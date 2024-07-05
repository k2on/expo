package expo.modules.filesystem.next

import android.net.Uri
import expo.modules.kotlin.apifeatures.EitherType
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.typedarray.TypedArray
import expo.modules.kotlin.types.Either
import java.io.File
import java.net.URI

class FileSystemNextModule : Module() {

  @OptIn(EitherType::class)
  override fun definition() = ModuleDefinition {
    Name("FileSystemNext")

    Class(FileSystemNextFile::class) {
      Constructor { path: URI ->
        FileSystemNextFile(File(path.path))
      }

      Function("delete") { file: FileSystemNextFile ->
        file.delete()
      }
      Function("validatePath") { file: FileSystemNextFile ->
        file.validatePath()
      }

      Function("create") { file: FileSystemNextFile ->
        file.create()
      }

      Function("write") { file: FileSystemNextFile, content: Either<String, TypedArray> ->
        file.write(content)
      }

      Function("text") { file: FileSystemNextFile ->
        file.text()
      }

      Function("exists") { file: FileSystemNextFile ->
        file.exists()
      }

      Function("copy") { file: FileSystemNextFile, destination: FileSystemNextPath ->
        file.copy(destination)
      }


    Function("move") { file: FileSystemNextFile, destination: FileSystemNextPath ->
        file.move(destination)
    }

      Property("path")
        .get { file: FileSystemNextFile -> return@get file.path.toURI() }
    }

    Class(FileSystemNextDirectory::class) {
      Constructor { path: URI ->
        FileSystemNextDirectory(File(path.path))
      }

      Function("delete") { directory: FileSystemNextDirectory ->
        directory.delete()
      }

      Function("create") { directory: FileSystemNextDirectory ->
        directory.create()
      }

      Function("exists") { directory: FileSystemNextDirectory ->
        directory.exists()
      }

      Function("validatePath") { directory: FileSystemNextDirectory ->
        directory.validatePath()
      }
        Function("copy") { directory: FileSystemNextDirectory, destination: FileSystemNextPath ->
            directory.copy(destination)
        }

      Property("path")
        .get { directory: FileSystemNextDirectory -> return@get directory.path.toURI() }
        .set { directory: FileSystemNextDirectory, newPath: String ->
          directory.path = File(URI(newPath).path)
        }
    }
  }
}
