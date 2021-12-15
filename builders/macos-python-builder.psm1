using module "./nix-python-builder.psm1"

class macOSPythonBuilder : NixPythonBuilder {
    <#
    .SYNOPSIS
    MacOS Python builder class.

    .DESCRIPTION
    Contains methods that required to build macOS Python artifact from sources. Inherited from base NixPythonBuilder.

    .PARAMETER platform
    The full name of platform for which Python should be built.

    .PARAMETER version
    The version of Python that should be built.

    #>

    macOSPythonBuilder(
        [semver] $version,
        [string] $architecture,
        [string] $platform
    ) : Base($version, $architecture, $platform) { }

    [void] PrepareEnvironment() {
	Execute-Command -Command "sudo rm -fr /usr/local/*"
	Execute-Command  -Command "sudo curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash -"
        Execute-Command -Command "brew install zlib"
        <#
        .SYNOPSIS
        Prepare system environment by installing dependencies and required packages.
        #>
    }

    [void] Configure() {
        <#
        .SYNOPSIS
        Execute configure script with required parameters.
        #>

        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()
        $configureString = "./configure"
        $configureString += " --prefix=$pythonBinariesLocation"
        $configureString += " --enable-optimizations"
        $configureString += " --enable-shared"
        $configureString += " --with-lto"

        ### OS X 10.11, Apple no longer provides header files for the deprecated system version of OpenSSL.
        ### Solution is to install these libraries from a third-party package manager,
        ### and then add the appropriate paths for the header and library files to configure command.
        ### Link to documentation (https://cpython-devguide.readthedocs.io/setup/#build-dependencies)
        if ($this.Version -lt "3.7.0") {
            $env:LDFLAGS = "-L/usr/local/opt/openssl@1.1/lib -L/usr/local/opt/zlib/lib"
            $env:CFLAGS = "-I/usr/local/opt/openssl@1.1/include -I/usr/local/opt/zlib/include"
        } else {
            $configureString += " --with-openssl=/usr/local/opt/openssl@1.1"
        }

        ### Compile with support of loadable sqlite extensions. Unavailable for Python 2.*
        ### Link to documentation (https://docs.python.org/3/library/sqlite3.html#sqlite3.Connection.enable_load_extension)
        if ($this.Version -ge "3.2.0") {
            $configureString += " --enable-loadable-sqlite-extensions"
            $env:LDFLAGS += " -L$(brew --prefix sqlite3)/lib"
            $env:CFLAGS += " -I$(brew --prefix sqlite3)/include"
            $env:CPPFLAGS += "-I$(brew --prefix sqlite3)/include"
        }

        Execute-Command -Command "sudo ln -s /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX11.1.sdk/System/Library/Frameworks/Tk.framework/Versions/8.5/Headers/X11/ /usr/local/include"

        Execute-Command -Command $configureString
    }
}
