#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
Update or create an Apple XCode project localization strings file.

TODO: handle localization domains
'''

import sys
import os
import os.path
import re
import tempfile
import subprocess
import codecs
import unittest
import optparse
import shutil
import logging


ENCODINGS = ['utf16', 'utf8']


class LocalizedString(object):
    ''' A localized string from a strings file '''
    COMMENT_EXPR = re.compile(
        # Line start
        '^\w*'
        # Comment
        '/\* (?P<comment>.+) \*/'
        # End of line
        '\w*$'
    )
    LOCALIZED_STRING_EXPR = re.compile(
        # Line start
        '^'
        # Key
        '"(?P<key>.+)"'
        # Equals
        ' ?= ?'
        # Value
        '"(?P<value>.+)"'
        # Whitespace
        ';'
        # Comment
        '(?: /\* (?P<comment>.+) \*/)?'
        # End of line
        '$'
    )

    @classmethod
    def parse_comment(cls, comment):
        '''
        Extract the content of a comment line from a strings file.
        Returns the comment string or None if the line doesn't match.
        '''
        result = cls.COMMENT_EXPR.match(comment)
        if result != None:
            return result.group('comment')
        else:
            return None

    @classmethod
    def from_line(cls, line):
        '''
        Extract the content of a string line from a strings file.
        Returns a LocalizedString instance or None if the line doesn't match.

        TODO: handle whitespace restore
        '''
        result = cls.LOCALIZED_STRING_EXPR.match(line)
        if result != None:
            return cls(
                result.group('key'),
                result.group('value'),
                result.group('comment')
            )
        else:
            return None

    def __init__(self, key, value=None, comment=None):
        super(LocalizedString, self).__init__()
        self.key = key
        self.value = value
        self.comment = comment

    def is_raw(self):
        '''
        Return True if the localized string has not been translated.
        '''
        return self.value == self.key

    def __str__(self):
        if self.comment:
            return '"%s" = "%s"; /* %s */' % (
                self.key or '', self.value or '', self.comment
            )
        else:
            return '"%s" = "%s";' % (self.key or '', self.value or '')


def strings_from_folder(folder_path, extensions=None, exclude=None):
    '''
    Recursively scan folder_path for files containing localizable strings.
    Run genstrings on these files and extract the strings.
    Returns a dictionnary of LocalizedString instances, indexed by key.
    '''
    localized_strings = {}
    code_file_paths = []
    if extensions == None:
        extensions = frozenset(['m', 'mm', 'swift'])
    if exclude == None: 
        exclude = frozenset(['ImportedSources','Pods'])
    logging.debug('Scanning for source files in %s', folder_path)

    for dir_path, dir_names, file_names in os.walk(folder_path):
        dir_names[:] = [d for d in dir_names if d not in exclude]
        for file_name in file_names:
            extension = file_name.rpartition('.')[2]
            if extension in extensions:
                code_file_path = os.path.join(dir_path, file_name)
                code_file_paths.append(code_file_path)

    logging.debug('Found %d files', len(code_file_paths))
    logging.debug('Running genstrings')
    temp_folder_path = tempfile.mkdtemp()
    arguments = ['genstrings', '-u', '-o', temp_folder_path]
    arguments.extend(code_file_paths)
    logging.debug('Here are the argumengts %s', arguments)
    subprocess.call(arguments)

    temp_file_path = os.path.join(temp_folder_path, 'Localizable.strings')
    if os.path.exists(temp_file_path):
        logging.debug('Analysing genstrings content')
        localized_strings = strings_from_file(temp_file_path)
        os.remove(temp_file_path)
    else:
        logging.debug('No translations found')

    shutil.rmtree(temp_folder_path)

    return localized_strings


def strings_from_file(file_path):
    '''
    Try to autodetect file encoding and call strings_from_encoded_file on the
    file at file_path.
    Returns a dictionnary of LocalizedString instances, indexed by key.
    Returns an empty dictionnary if the encoding is wrong.
    '''
    for current_encoding in ENCODINGS:
        try:
            return strings_from_encoded_file(file_path, current_encoding)
        except UnicodeError:
            pass

    logging.error(
        'Cannot determine encoding for file %s among %s',
        file_path,
        ', '.join(ENCODINGS)
    )

    return {}


def strings_from_encoded_file(file_path, encoding):
    '''
    Extract the strings from the file at file_path.
    Returns a dictionnary of LocalizedString instances, indexed by key.
    '''
    localized_strings = {}

    with codecs.open(file_path, 'r', encoding) as content:
        comment = None

        for line in content:
            line = line.strip()
            if not line:
                comment = None
                continue

            current_comment = LocalizedString.parse_comment(line)
            if current_comment:
                if current_comment != 'No comment provided by engineer.':
                    comment = current_comment
                continue

            localized_string = LocalizedString.from_line(line)
            if localized_string:
                if not localized_string.comment:
                    localized_string.comment = comment
                localized_strings[localized_string.key] = localized_string
            else:
                logging.error('Could not parse: %s', line.strip())

    return localized_strings


def strings_to_file(localized_strings, file_path, encoding='utf16'):
    '''
    Write a strings file at file_path containing string in
    the localized_strings dictionnary.
    The strings are alphabetically sorted.
    '''
    with codecs.open(file_path, 'w', encoding) as output:
        for localized_string in sorted_strings_from_dict(localized_strings):
            output.write('%s\n' % localized_string)


def update_file_with_strings(file_path, localized_strings):
    '''
    Try to autodetect file encoding and call update_encoded_file_with_strings
    on the file at file_path.
    The file at file_path must exist or this function will raise an exception.
    '''
    for current_encoding in ENCODINGS:
        try:
            return update_encoded_file_with_strings(
                file_path,
                localized_strings,
                current_encoding
            )
        except UnicodeError:
            pass

    logging.error(
        'Cannot determine encoding for file %s among %s',
        file_path,
        ', '.join(ENCODINGS)
    )

    return {}


def update_encoded_file_with_strings(
    file_path,
    localized_strings,
    encoding='utf16'
):
    '''
    Update file at file_path with translations from localized_strings, trying
    to preserve the initial formatting by only removing the old translations,
    updating the current ones and adding the new translations at the end of
    the file.
    The file at file_path must exist or this function will raise an exception.
    '''
    output_strings = []

    keys = set()
    with codecs.open(file_path, 'r', encoding) as content:
        for line in content:
            current_string = LocalizedString.from_line(line.strip())
            if current_string:
                key = current_string.key
                localized_string = localized_strings.get(key, None)
                if localized_string:
                    keys.add(key)
                    output_strings.append(str(localized_string))
            else:
                output_strings.append(line[:-1])

    new_strings = []
    for value in localized_strings.values():
        if value.key not in keys:
            new_strings.append(str(value))

    if len(new_strings) != 0:
        output_strings.append('')
        output_strings.append('/* New strings */')
        new_strings.sort()
        output_strings.extend(new_strings)

    with codecs.open(file_path, 'w', encoding) as output:
        output.write('\n'.join(output_strings))
        # Always add a new line at the end of the file
        output.write('\n')


def match_strings(scanned_strings, reference_strings):
    '''
    Complete scanned_strings with translations from reference_strings.
    Return the completed scanned_strings dictionnary.
    scanned_strings is not affected.
    Strings in reference_strings and not in scanned_strings are not copied.
    '''
    final_strings = {}

    for key, value in scanned_strings.items():
        reference_value = reference_strings.get(key, None)
        if reference_value:
            if reference_value.is_raw():
                # Mark non-translated strings
                logging.debug('[raw]     %s', key)
                final_strings[key] = value
            else:
                # Reference comment comes from the code
                reference_value.comment = value.comment
                final_strings[key] = reference_value
        else:
            logging.debug('[new]     %s', key)
            final_strings[key] = value

    final_keys = set(final_strings.keys())
    for key in reference_strings.keys():
        if key not in final_keys:
            logging.debug('[deleted] %s', key)

    return final_strings


def merge_dictionaries(reference_dict, import_dict):
    '''
    Return a dictionnary containing key/values from reference_dict
    and import_dict.
    In case of conflict, the value from reference_dict is chosen.
    '''
    final_dict = reference_dict.copy()

    reference_dict_keys = set(reference_dict.keys())
    for key, value in import_dict.items():
        if key not in reference_dict_keys:
            final_dict[key] = value

    return final_dict


def sorted_strings_from_dict(strings):
    '''
    Return an array containing the string objects sorted alphabetically.
    '''
    keys = list(strings.keys())
    keys.sort()

    values = []
    for key in keys:
        values.append(strings[key])

    return values


class Tests(unittest.TestCase):
    ''' Unit Tests '''

    def test_comment(self):
        ''' Test comment pattern '''
        result = LocalizedString.COMMENT_EXPR.match('/* Testing Comments */')
        self.assertNotEqual(result, None, 'Pattern not recognized')
        self.assertEqual(result.group('comment'), 'Testing Comments',
            'Incorrect pattern content: [%s]' % result.group('comment')
        )

    def test_localized_string(self):
        ''' Test localized string pattern '''
        result = LocalizedString.LOCALIZED_STRING_EXPR.match(
            '"KEY" = "VALUE";'
        )
        self.assertNotEqual(result, None, 'Pattern not recognized')
        self.assertEqual(result.group('key'), 'KEY',
            'Incorrect comment content: [%s]' % result.group('key')
        )
        self.assertEqual(result.group('value'), 'VALUE',
            'Incorrect comment content: [%s]' % result.group('value')
        )
        self.assertEqual(result.group('comment'), None,
            'Incorrect comment content: [%s]' % result.group('comment')
        )

    def test_localized_comment_string(self):
        ''' Test localized string with comment pattern '''
        result = LocalizedString.LOCALIZED_STRING_EXPR.match(
            '"KEY" = "VALUE"; /* COMMENT */'
        )
        self.assertNotEqual(result, None, 'Pattern not recognized')
        self.assertEqual(result.group('key'), 'KEY',
            'Incorrect comment content: [%s]' % result.group('key')
        )
        self.assertEqual(result.group('value'), 'VALUE',
            'Incorrect comment content: [%s]' % result.group('value')
        )
        self.assertEqual(result.group('comment'), 'COMMENT',
            'Incorrect comment content: [%s]' % result.group('comment')
        )


def main():
    ''' Parse the command line and do what it is telled to do '''
    parser = optparse.OptionParser(
        'usage: %prog [options] Localizable.strings [source folders]'
    )
    parser.add_option(
        '-v',
        '--verbose',
        action='store_true',
        dest='verbose',
        default=False,
        help='Show debug messages'
    )
    parser.add_option(
        '',
        '--dry-run',
        action='store_true',
        dest='dry_run',
        default=False,
        help='Do not write to the strings file'
    )
    parser.add_option(
        '',
        '--import',
        dest='import_file',
        help='Import strings from FILENAME'
    )
    parser.add_option(
        '',
        '--overwrite',
        action='store_true',
        dest='overwrite',
        default=False,
        help='Overwrite the strings file, ignores original formatting'
    )
    parser.add_option(
        '',
        '--unittests',
        action='store_true',
        dest='unittests',
        default=False,
        help='Run unit tests (debug)'
    )

    (options, args) = parser.parse_args()

    logging.basicConfig(
        format='%(message)s',
        level=options.verbose and logging.DEBUG or logging.INFO
    )

    if options.unittests:
        suite = unittest.TestLoader().loadTestsFromTestCase(Tests)
        return unittest.TextTestRunner(verbosity=2).run(suite)

    if len(args) == 0:
        parser.error('Please specify a strings file')

    strings_file = args[0]

    input_folders = ['.']
    if len(args) > 1:
        input_folders = args[1:]

    scanned_strings = {}
    for input_folder in input_folders:
        if not os.path.isdir(input_folder):
            logging.error('Input path is not a folder: %s', input_folder)
            return 1

        # TODO: allow to specify file extensions to scan
        scanned_strings = merge_dictionaries(
            scanned_strings,
            strings_from_folder(input_folder)
        )

    if options.import_file:
        logging.debug(
            'Reading import file: %s',
            options.import_file
        )
        reference_strings = strings_from_file(options.import_file)
        scanned_strings = match_strings(
            scanned_strings,
            reference_strings
        )

    if os.path.isfile(strings_file):
        logging.debug(
            'Reading strings file: %s',
            strings_file
        )
        reference_strings = strings_from_file(
            strings_file
        )
        scanned_strings = match_strings(
            scanned_strings,
            reference_strings
        )

    if options.dry_run:
        logging.info(
            'Dry run: the strings file has not been updated'
        )
    else:
        try:
            if os.path.exists(strings_file) and not options.overwrite:
                update_file_with_strings(strings_file, scanned_strings)
            else:
                strings_to_file(scanned_strings, strings_file)
        except IOError as exc:
            logging.error('Error writing to file %s: %s', strings_file, exc)
            return 1

        logging.info(
            'Strings were generated in %s',
            strings_file
        )

    return 0


if __name__ == '__main__':
    sys.exit(main())
