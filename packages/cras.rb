require 'package'

class Cras < Package
  description 'ChromeOS Audio Server'
  homepage 'https://www.chromium.org/chromium-os/chromiumos-design-docs/cras-chromeos-audio-server'
  version 'stabilize-13360.B'
  compatibility 'aarch64,armv7l,x86_64'
  case ARCH
  when 'aarch64', 'armv7l', 'x86_64'
    source_url 'https://chromium.googlesource.com/chromiumos/third_party/adhd/+/refs/heads/stabilize-13360.B/cras/README.md'
    source_sha256 '27f138b73f3e6b46c6f1af509ed6887c76fc234c026ce08383712a87efdf97d6'
    depends_on 'alsa_lib'
    depends_on 'ladspa'
    depends_on 'iniparser'
    depends_on 'speexdsp'
    depends_on 'sbc'
    depends_on 'dbus'
    depends_on 'rust' => ':build'
    depends_on 'llvm' => ':build'
  end

  binary_url ({
  })
  binary_sha256 ({
  })

  def self.build
    system 'git', 'clone', 'https://chromium.googlesource.com/chromiumos/third_party/adhd', '-b', version, '.'
    Dir.chdir('cras') do
      system 'cat << _EOF_ > 10-cras.conf
pcm.cras {
    type cras
    hint {
        show on
        description "Chromium OS Audio Server"
    }
}
ctl.cras {
    type cras
}
# Default: route all audio through the CRAS plugin.
pcm.!default {
    type cras
    hint {
        show on
        description "Default ALSA Output (currently Chromium OS Audio Server)"
    }
}
ctl.!default {
    type cras
}
_EOF_'
      system './git_prepare.sh'
      ENV['CC'] = 'clang'
      ENV['CXX'] = 'clang++'
      ENV['CXXFLAGS'] = "-g -O2 -std=gnu++11 -Wall"
      ENV['CFLAGS'] = "-g -O2 -Wall"
      system './configure',
             "--prefix=#{CREW_PREFIX}",
             "--libdir=#{CREW_LIB_PREFIX}",
             '--disable-alsa-plugin',
             '--disable-static',
             '--disable-webrtc-apm',
             '--enable-sse42',
             '--enable-avx',
             '--enable-avx2',
             '--enable-fma'
      system "make -j#{CREW_NPROC}"
    end
  end

  def self.install
    Dir.chdir('cras') do
      system 'make', "DESTDIR=#{CREW_DEST_DIR}", "install"
      FileUtils.mkdir_p CREW_DEST_PREFIX + '/share/alsa/alsa.conf.d/'
      FileUtils.install '10-cras.conf', CREW_DEST_PREFIX + '/share/alsa/alsa.conf.d/'
    end
  end
end
