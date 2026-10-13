#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
Maintain the About screens of VLC for iOS and tvOS.

  update_about.py generate
      Rewrite the author, translator and third-party library lists in
      Sources/About/{iOS,tvOS}/About Contents.html. Authors are taken from
      git (honoring .mailmap) and ordered by their number of commits, the
      libraries come from update_about.json.

  update_about.py check
      Report what needs a human look before the next update:
      - contributors whose name still is a handle (add them to .mailmap)
      - contrib, Pod, Swift package and VLCMediaLibraryKit dependency
        versions that differ from the ones recorded in update_about.json
      - libraries found in or missing from the shipped VLCKit and
        VLCMediaLibraryKit binaries (needs the Swift package artifacts that
        Xcode puts in DerivedData and a VLC checkout, ../vlc by default)
      - third-party files in the app sources that are not credited

After changing a library's copyright, license or version, update its entry
in update_about.json and run "generate".
'''

import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys
import unicodedata

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'update_about.json')
ABOUT = {
    'ios': os.path.join(ROOT, 'Sources', 'About', 'iOS', 'About Contents.html'),
    'tvos': os.path.join(ROOT, 'Sources', 'About', 'tvOS', 'About Contents.html'),
}
PODFILE_LOCK = os.path.join(ROOT, 'Podfile.lock')
PACKAGE_RESOLVED = os.path.join(ROOT, 'VLC.xcworkspace', 'xcshareddata', 'swiftpm', 'Package.resolved')

AUTHORS_EXPR = re.compile(r'(?<=Written by )[^\n]*?(?=\s*<br /><br />Web Interface by)')
THANKS_EXPR = re.compile(r'(?<=tests, ideas and translations:<br />\n)[^\n]*?(?=, Transifex VLC project team)')
LIBRARIES_EXPR = re.compile(
    r'(<p align="center">VLC for (?:iOS|tvOS) makes use of the following libraries, fonts and frameworks:</p>\n)'
    r'.*?(?=<h3 id="mplv2">)', re.S)
L10N_FILE_EXPR = re.compile(r'(\.lproj/|\.strings$|\.stringsdict$|\.po$|\.pot$|\.xliff$|\.xcstrings$|/po/)')
L10N_SUBJECT_EXPR = re.compile(r'^l10n|translation', re.I)
HANDLE_EXPR = re.compile(r'^[^ ]+$|\d|^[a-z]')


def load_data():
    with open(DATA, encoding='utf-8') as f:
        return json.load(f)


def git(*args, cwd=ROOT):
    return subprocess.run(['git', '-C', cwd] + list(args), capture_output=True,
                          text=True, check=True).stdout


# Authors

def count_commits():
    ''' Returns the total and the non-translation commit count per author '''
    log = git('log', '--no-merges', '--use-mailmap', '--format=\x01%aN\x02%s', '--name-only', 'HEAD')
    total, code = collections.Counter(), collections.Counter()
    for chunk in log.split('\x01')[1:]:
        head, _, files = chunk.partition('\n')
        name, subject = head.split('\x02', 1)
        name = unicodedata.normalize('NFC', name)
        files = [f for f in files.split('\n') if f.strip()]
        total[name] += 1
        translation = (files and all(L10N_FILE_EXPR.search(f) for f in files)) or L10N_SUBJECT_EXPR.search(subject)
        if not translation:
            code[name] += 1
    return total, code


def author_lists(rules):
    ''' Returns the "Written by", "with additions by" and thank-you lists '''
    total, code = count_commits()
    excluded = set(rules['excluded']) | set(rules['credited_elsewhere'])
    authors = {n for n in total if code[n] and n not in rules['always_thanks']}
    authors |= set(rules['always_authors']) | set(rules['authors_without_commits'])
    authors -= excluded
    thanks = ({n for n in total if n not in authors} | set(rules['thanks_without_commits'])) - excluded

    def ordered(names):
        return sorted(names, key=lambda n: (-total[n], n.casefold()))
    authors, thanks = ordered(authors), ordered(thanks)
    written = [n for n in authors if total[n] >= rules['written_by_min_commits']]
    additions = [n for n in authors if total[n] < rules['written_by_min_commits']]
    return written, additions, thanks, total


def join_and(items):
    return ', '.join(items[:-1]) + ', and ' + items[-1]


def authors_html(platform, rules, written, additions):
    def name(n):
        html = rules['html_names'].get(n, n)
        if platform == 'ios' and n in rules['links']:
            return '<a href="%s">%s</a>' % (rules['links'][n], html)
        return html
    return (', '.join(name(n) for n in written) + ', <br />with additions by '
            + join_and([name(n) for n in additions]))


# Libraries

def library_html(platform, library):
    copyright = library['copyright']
    if platform == 'ios':
        title = library['name']
        if library.get('url'):
            title = '<a href="%s">%s</a>' % (library['url'], library['name'])
        license = library['license']
        if library.get('anchor'):
            license = '<a href="#%s">%s</a>' % (library['anchor'], license)
        return '&nbsp;&nbsp;&nbsp;&nbsp;%s<br />\n%s - %s<br />\n<br />\n' % (title, copyright, license)
    copyright = re.sub(r'<a [^>]*>(.*?)</a>', r'\1', copyright)
    return '&nbsp;&nbsp;&nbsp;&nbsp;<b>%s</b>\n<br />%s - %s\n<br /><br />\n' % (
        library['name'], copyright, library['license'])


def libraries_html(platform, libraries):
    return '<br />\n' + ''.join(library_html(platform, l) for l in libraries
                                if platform in l['platforms']) + '<br />\n'


def generate(_):
    data = load_data()
    rules = data['authors']
    written, additions, thanks, _ = author_lists(rules)
    for platform, path in ABOUT.items():
        with open(path, encoding='utf-8') as f:
            html = f.read()
        html, authors_count = AUTHORS_EXPR.subn(lambda _: authors_html(platform, rules, written, additions), html)
        html, thanks_count = THANKS_EXPR.subn(lambda _: ', '.join(thanks), html)
        html, libraries_count = LIBRARIES_EXPR.subn(
            lambda m: m.group(1) + libraries_html(platform, data['libraries']), html)
        if (authors_count, thanks_count, libraries_count) != (1, 1, 1):
            sys.exit('%s: could not find the author, translator or library list' % path)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
    print('Updated %d authors, %d translators and %d libraries'
          % (len(written) + len(additions), len(thanks), len(data['libraries'])))


# Checks

def contrib_version(rules_mak):
    ''' A signature of all version and hash assignments of a contrib rules.mak '''
    values = re.findall(r'^[A-Z0-9_]*(?:VERSION|HASH)[A-Z0-9_]*\s*:?=\s*(\S+)', rules_mak, re.M)
    return ' '.join(v for v in values if '$(' not in v)


def vlckit_contrib_overrides(vlckit):
    ''' Contrib versions that VLCKit's own patches change, e.g. live555 '''
    overrides = {}
    for patch in sorted(glob.glob(os.path.join(vlckit, 'libvlc', 'patches', '*.patch'))):
        with open(patch, encoding='utf-8', errors='replace') as f:
            text = f.read()
        for section in re.split(r'^diff --git ', text, flags=re.M)[1:]:
            match = re.match(r'a/contrib/src/([^/]+)/rules\.mak', section)
            if not match:
                continue
            added = '\n'.join(l[1:] for l in section.split('\n') if l.startswith('+') and not l.startswith('+++'))
            version = contrib_version(added)
            if version:
                overrides[match.group(1)] = version
    return overrides


def symbols(path):
    return subprocess.run(['nm', '-a', path], capture_output=True, text=True).stdout


def dsym_contrib_dirs(path):
    with open(path, 'rb') as f:
        blob = f.read()
    return {d.decode() for d in re.findall(rb'/contrib/contrib-[^/]+/([^/\x00 ]+)', blob)}


def find_dsym(artifacts, framework, slice_name):
    pattern = os.path.join(artifacts, '**', framework + '.xcframework', slice_name, 'dSYMs',
                           framework + '.framework.dSYM', 'Contents', 'Resources', 'DWARF', framework)
    found = glob.glob(pattern, recursive=True)
    return found[0] if found else None


def check(args):
    data = load_data()
    libraries = data['libraries']
    findings = collections.defaultdict(list)

    # Contributors still known by a handle only
    written, additions, thanks, total = author_lists(data['authors'])
    known = set(data['authors']['known_handles'])
    for name in written + additions + thanks:
        if HANDLE_EXPR.search(name) and name not in known and total[name]:
            findings['Contributors known by a handle only (add them to .mailmap)'].append(
                '%s (%d commits)' % (name, total[name]))

    # Swift packages
    with open(PACKAGE_RESOLVED, encoding='utf-8') as f:
        pins = {p['identity']: p['state'].get('version') or p['state'].get('revision')
                for p in json.load(f)['pins']}
    recorded = {l['source']['spm']: l for l in libraries if 'spm' in l['source']}
    for identity, version in sorted(pins.items()):
        if identity not in recorded:
            findings['Swift packages without an entry'].append('%s %s' % (identity, version))
        elif recorded[identity]['source']['version'] != version:
            findings['Changed versions'].append('%s: %s -> %s (Swift package %s)' % (
                recorded[identity]['name'], recorded[identity]['source']['version'], version, identity))

    # Pods
    with open(PODFILE_LOCK, encoding='utf-8') as f:
        lock = f.read().split('\n\n')[0]
    pods = dict(re.findall(r'^  - ([^/ ]+)(?:/\S+)? \(([^)]+)\)', lock, re.M))
    recorded = {p: l for l in libraries for p in l['source'].get('pod', [])}
    for pod, version in sorted(pods.items()):
        if pod not in recorded:
            findings['Pods without an entry'].append('%s %s' % (pod, version))
        elif recorded[pod]['source']['version'] != version:
            findings['Changed versions'].append('%s: %s -> %s (Pod %s)' % (
                recorded[pod]['name'], recorded[pod]['source']['version'], version, pod))

    # Files bundled with the app
    credited = set()
    for library in libraries:
        for pattern in library['source'].get('files', []):
            matches = glob.glob(os.path.join(ROOT, pattern), recursive=True)
            if not matches:
                findings['Credited files that no longer exist'].append('%s: %s' % (library['name'], pattern))
            credited.update(os.path.relpath(m, ROOT) for m in matches)
    sources = git('ls-files', '--', 'Sources', 'Resources/web').split('\n')
    for path in sources:
        if not path or path in credited or not re.search(r'\.(m|h|swift|js|css|c|cpp|py)$', path) \
                or path.startswith('Sources/About/'):
            continue
        with open(os.path.join(ROOT, path), encoding='utf-8', errors='replace') as f:
            head = f.read(4096)
        if re.search(r'copyright', head, re.I) and not re.search(r'VideoLAN|Videolabs|VLC authors', head, re.I):
            findings['Third-party files without an entry'].append(path)

    # Shipped binaries
    derived = sorted(glob.glob(os.path.expanduser(args.derived_data)), key=os.path.getmtime)
    checkouts = os.path.join(derived[-1], 'checkouts') if derived else None
    artifacts = os.path.join(derived[-1], 'artifacts') if derived else None
    if not derived:
        findings['Skipped'].append('no Swift package artifacts in %s, build the app once' % args.derived_data)
    else:
        vlckit = os.path.join(checkouts, 'VLCKit')
        with open(os.path.join(vlckit, 'compileAndBuildVLCKit.sh'), encoding='utf-8') as f:
            vlc_commit = re.search(r'^TESTEDHASH="([0-9a-f]+)"', f.read(), re.M).group(1)
        overrides = vlckit_contrib_overrides(vlckit)
        with open(os.path.join(checkouts, 'VLCMediaLibraryKit', 'buildVLCMediaLibraryKit.sh'), encoding='utf-8') as f:
            mlkit_script = f.read()

        for library in libraries:
            source = library['source']
            if 'contrib' in source:
                try:
                    rules_mak = git('show', '%s:contrib/src/%s/rules.mak' % (vlc_commit, source['contrib']), cwd=args.vlc)
                    version = overrides.get(source['contrib'], contrib_version(rules_mak))
                except subprocess.CalledProcessError:
                    version = 'missing at VLC %s' % vlc_commit
                if version != source['version']:
                    findings['Changed versions'].append('%s: %s -> %s (contrib %s at VLC %s)' % (
                        library['name'], source['version'], version, source['contrib'], vlc_commit))
            elif 'vlckit' in source and source['version'] != vlc_commit:
                findings['Changed versions'].append('%s: VLC %s -> %s (VLCKit TESTEDHASH)' % (
                    library['name'], source['version'], vlc_commit))
            elif 'vlcmlkit' in source:
                match = re.search(r'^%s="([^"]+)"' % source['vlcmlkit'], mlkit_script, re.M)
                version = match.group(1) if match else 'missing'
                if version != source['version']:
                    findings['Changed versions'].append('%s: %s -> %s (VLCMediaLibraryKit %s)' % (
                        library['name'], source['version'], version, source['vlcmlkit']))

        known_dirs = {l['source'].get('dsym_dir', l['source'].get('contrib')) for l in libraries}
        for platform, slice_name in (('ios', 'ios-arm64'), ('tvos', 'tvos-arm64')):
            dsyms = [find_dsym(artifacts, f, slice_name) for f in ('VLCKit', 'VLCMediaLibraryKit')]
            if None in dsyms:
                findings['Skipped'].append('no %s dSYMs for VLCKit and VLCMediaLibraryKit' % slice_name)
                continue
            table = ''.join(symbols(d) for d in dsyms)
            for library in libraries:
                if not library.get('symbol'):
                    continue
                shipped = library['symbol'] in table
                listed = platform in library['platforms']
                if shipped and not listed:
                    findings['Shipped but not credited'].append('%s on %s' % (library['name'], platform))
                elif listed and not shipped:
                    findings['Credited but not shipped'].append('%s on %s' % (library['name'], platform))
            for directory in sorted(dsym_contrib_dirs(dsyms[0]) - known_dirs):
                findings['Contribs in the binary without an entry'].append('%s on %s' % (directory, platform))

    for title, items in findings.items():
        print('%s:' % title)
        for item in sorted(set(items)):
            print('  ' + item)
    if not findings:
        print('Nothing to update')
    return 1 if findings else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('generate', help='rewrite the lists in both About screens')
    checker = commands.add_parser('check', help='report what changed since the last update')
    checker.add_argument('--vlc', default=os.path.join(os.path.dirname(ROOT), 'vlc'),
                         help='VLC git checkout used to look up the contrib versions (default: ../vlc)')
    checker.add_argument('--derived-data', default='~/Library/Developer/Xcode/DerivedData/VLC-*/SourcePackages',
                         help='Xcode SourcePackages folder with the VLCKit and VLCMediaLibraryKit artifacts')
    args = parser.parse_args()
    return generate(args) if args.command == 'generate' else check(args)


if __name__ == '__main__':
    sys.exit(main())
