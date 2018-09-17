class Qemu < Formula
  desc "x86 and PowerPC Emulator"
  homepage "http://www.qemu.org"
  url "https://download.qemu.org/qemu-3.0.0.tar.xz"
  sha256 "8d7af64fe8bd5ea5c3bdf17131a8b858491bcce1ee3839425a6d91fb821b5713"
  head "https://git.qemu.org/git/qemu.git"

  option "with-docs", "Install QEMU documentation locally"
  option "with-hvf", "Install Hypervisor.framework hardware acceleration support"
  option "with-hax", "Instal Intel HAXM hardware acceleration support"

  depends_on "pkg-config" => :build
  depends_on "libtool" => :build
  depends_on "libffi" => :build
  depends_on "gettext" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "jpeg"
  depends_on "gnutls"
  depends_on "glib" => :build
  depends_on "ncurses"
  depends_on "pixman" => :build
  depends_on "libpng" => :recommended
  depends_on "vde" => :optional
  depends_on "sdl2" => :optional
  depends_on "gtk+3" => :optional
  depends_on "libssh2" => :optional
  depends_on "libusb" => :optional

  deprecated_option "with-sdl" => "with-sdl2"
  deprecated_option "with-gtk+" => "with-gtk+3"

  fails_with :gcc_4_0 do
    cause "qemu requires a compiler with support for the __thread specifier"
  end

  fails_with :gcc do
    cause "qemu requires a compiler with support for the __thread specifier"
  end

  resource "test-image" do
        url "https://dl.bintray.com/homebrew/mirror/FD12FLOPPY.zip"
    sha256 "81237c7b42dc0ffc8b32a2f5734e3480a3f9a470c50c14a9c4576a2561a35807"
  end

  def install
    ENV["LIBTOOL"] = "glibtool"
    
    # Get number of logical CPU's on the system
    ncpus = `sysctl -n hw.ncpu`
    ncpus_int = ncpus.to_i
    # puts ncpus_int

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-guest-agent
      --enable-curses
      --extra-cflags=-DNCURSES_WIDECHAR=1
    ]

    args << "--enable-docs" if build.with?("docs")
    args << "--enable-libusb" if build.with?("libusb")
    args << "--enable-hvf" if build.with?("hvf")
    args << "--enable-hax" if build.with?("hax")

    # Cocoa and SDL2/GTK+ UIs cannot both be enabled at once.
    if build.with?("sdl2") || build.with?("gtk+3")
      args << "--disable-cocoa"
    else
      args << "--enable-cocoa"
    end

    args << (build.with?("vde") ? "--enable-vde" : "--disable-vde")
    args << (build.with?("sdl2") ? "--enable-sdl" : "--disable-sdl")
    args << (build.with?("gtk+3") ? "--enable-gtk" : "--disable-gtk")
    args << (build.with?("libssh2") ? "--enable-libssh2" : "--disable-libssh2")

    system "./configure", *args
    # system "make 'V=1 -j#{ncpus_int}'"
    system "make" "V=1"
    system "make install"
  end

   test do
    expected = build.stable? ? version.to_s : "QEMU Project"
    assert_match expected, shell_output("#{bin}/qemu-system-i386 --version")
    resource("test-image").stage testpath
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info FLOPPY.img")
  end
end

