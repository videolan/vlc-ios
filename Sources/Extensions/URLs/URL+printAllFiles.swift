/*
 * This extension prints all files in a directory (including its subdirectories).
 * Created by vadian (https://stackoverflow.com/a/57640445)
*/

extension URL {
    func printAllFiles() {
        print("======== FILES CONTENTS START ========")
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        files.append(fileURL)
                    }
                } catch { print(error, fileURL) }
            }
            print(files)
        }
        print("======== FILES CONTENTS END ========")
    }
}
