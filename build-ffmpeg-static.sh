#!/bin/bash


# https://github.com/markus-perl/ffmpeg-build-script

VERSION=1.7
CWD=$(pwd)
PACKAGES="$CWD/packages"
WORKSPACE="$CWD/workspace"
CC=clang
LDFLAGS="-L${WORKSPACE}/lib -lm"
CFLAGS="-I${WORKSPACE}/include"
PKG_CONFIG_PATH="${WORKSPACE}/lib/pkgconfig"
ADDITIONAL_CONFIGURE_OPTIONS=""

#~ export NUMJOBS=2

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
	ADDITIONAL_CONFIGURE_OPTIONS="--enable-videotoolbox"
else
    MJOBS=4
fi

make_dir () {
	if [ ! -d $1 ]; then
		if ! mkdir $1; then
			printf "\n Failed to create dir %s" "$1";
			exit 1
		fi
	fi
}

remove_dir () {
	if [ -d $1 ]; then
		rm -r "$1"
	fi
}

download () {

	DOWNLOAD_PATH=$PACKAGES;

	if [ ! -z "$3" ]; then
		mkdir -p $PACKAGES/$3
		DOWNLOAD_PATH=$PACKAGES/$3
	fi;

	if [ ! -f "$DOWNLOAD_PATH/$2" ]; then

		echo "Downloading $1"
		curl -L --silent -o "$DOWNLOAD_PATH/$2" "$1"

		EXITCODE=$?
		if [ $EXITCODE -ne 0 ]; then
			echo ""
			echo "Failed to download $1. Exitcode $EXITCODE. Retrying in 10 seconds";
			sleep 10
			curl -L --silent -o "$DOWNLOAD_PATH/$2" "$1"
		fi

		EXITCODE=$?
		if [ $EXITCODE -ne 0 ]; then
			echo ""
			echo "Failed to download $1. Exitcode $EXITCODE";
			exit 1
		fi

		echo "... Done"

		if ! tar -xvf "$DOWNLOAD_PATH/$2" -C "$DOWNLOAD_PATH" 2>/dev/null >/dev/null; then
			echo "Failed to extract $2";
			exit 1
		fi

	fi
}

execute () {
	echo "$ $*"

	OUTPUT=$( "$@" 2>&1)

	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}
execute_verbose () {
	echo "$ $*"

	#~ OUTPUT=$($@ 2>&1)
	$@

	#~ if [ $? -ne 0 ]; then
        #~ echo "$OUTPUT"
        #~ echo ""
        #~ echo "Failed to Execute $*" >&2
        #~ exit 1
    #~ fi
}

build () {
	echo ""
	echo "building $1"
	echo "======================="
	
	if [ -f "$PACKAGES/$1.done" ]; then
		echo "$1 already built. Remove $PACKAGES/$1.done lockfile to rebuild it."
		return 1
	fi

	return 0
}

command_exists() {
    if ! [[ -x $(command -v "$1") ]]; then
        return 1
    fi

    return 0
}


build_done () {
	touch "$PACKAGES/$1.done"
}

echo "ffmpeg-build-script v$VERSION"
echo "========================="
echo ""

export USE_CLANG=1
#~ export FAST_BUILD=1


case "$1" in
"--cleanup")
	remove_dir $PACKAGES
	remove_dir $WORKSPACE
	echo "Cleanup done."
	echo ""
	exit 0
    ;;
"--build-clang")
        export USE_CLANG=1;
    ;;
"--build")

    ;;
*)
    echo "Usage: $0"
    echo "   --build: start building process"
    echo "   --cleanup: remove all working dirs"
    echo "   --help: show this help"
    echo "   FAST_BUILD=1: download pre-built static libs for other(non-av1) encoders"
    echo "   BUILD_RAV1E=1: build rav1e support"
    echo "   BUILD_SVT=1: build svt_av1 support"
    echo "   USE_CLANG=1: use clang-9 instead of gcc"
    echo ""
    exit 0
    ;;
esac


if [[ -n $BUILD_RAV1E ]]; then echo 'RAV1E build enabled';
else echo 'RAV1E build disabled';fi;
if [[ -n $BUILD_SVT ]]; then echo 'SVT-AV1 build enabled';
else echo 'SVT-AV1 build disabled';fi;
if [[ -n $FAST_BUILD ]]; then echo 'FAST_BUILD enabled';
else echo 'FAST_BUILD disabled';fi;
if [[ -n $USE_CLANG ]]; then echo 'USE_CLANG enabled';
else echo 'USE_CLANG disabled';fi;
echo "Using $MJOBS make jobs simultaneously."

make_dir $PACKAGES
make_dir $WORKSPACE

##install gcc-9 g++-9
#~ echo 'deb http://ftp.us.debian.org/debian testing main contrib non-free'|sudo tee -a /etc/apt/sources.list
#~ echo -e 'Package: *\nPin: release a=testing\nPin-Priority: 100'|sudo tee -a /etc/apt/preferences.d/testpref
#~ execute sudo apt-get update
#~ execute sudo apt-get install -t testing gcc-9 g++-9 -y
#~ execute sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
#~ execute sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100
#~ execute sudo update-alternatives --install /usr/bin/cpp cpp /usr/bin/g++-9 100





##install clang-9/clang++-9 and use it as the default C/C++ compiler
if [[ -n $USE_CLANG ]]; then
	echo 'USING CLANG-9 as compiler';
	#~ if ! command_exists "clang++-9"; then
                #~ echo 'INSTALLING CLANG-9 ...'
                #~ echo 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-9 main' >/tmp/myppa.list
                #~ sudo cp /tmp/myppa.list /etc/apt/sources.list.d/
                #~ wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
		#~ sudo apt update -y -qq > /dev/null 2> /dev/null
		#~ sudo apt install clang-9 -y -qq > /dev/null 2> /dev/null
		#~ sudo apt-get --purge remove gcc-6 gcc-7 -y   -qq > /dev/null 2> /dev/null
		#~ sudo update-alternatives  --install  /usr/bin/cpp cpp /usr/bin/clang++-9 100;
		#~ sudo update-alternatives  --install /usr/bin/c++ c++ /usr/bin/clang++-9 100;
		#~ sudo update-alternatives  --install /usr/bin/g++ g++ /usr/bin/clang++-9 100;
		#~ sudo update-alternatives  --install /usr/bin/cc cc /usr/bin/clang-9 100;
		#~ sudo update-alternatives  --install /usr/bin/gcc gcc /usr/bin/clang-9 100;
        echo 'INSTALLING CLANG-9 ...'
        #~ echo 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-9 main' >/tmp/myppa.list
        #~ echo 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main' >/tmp/myppa.list
        echo 'deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-12 main ' >/tmp/myppa.list
        sudo cp /tmp/myppa.list /etc/apt/sources.list.d/
        wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
        sudo apt update -y -qq > /dev/null 2> /dev/null
        #~ sudo apt install clang-9 -y -qq > /dev/null 2> /dev/null
        sudo apt install clang-12 -y -qq > /dev/null 2> /dev/null
        sudo apt-get --purge remove gcc-6 gcc-7 -y   -qq > /dev/null 2> /dev/null
        #~ sudo update-alternatives  --install  /usr/bin/cpp cpp /usr/bin/clang++-9 100;
        #~ sudo update-alternatives  --install /usr/bin/c++ c++ /usr/bin/clang++-9 100;
        #~ sudo update-alternatives  --install /usr/bin/g++ g++ /usr/bin/clang++-9 100;
        #~ sudo update-alternatives  --install /usr/bin/cc cc /usr/bin/clang-9 100;
        #~ sudo update-alternatives  --install /usr/bin/gcc gcc /usr/bin/clang-9 100;
        sudo update-alternatives  --install  /usr/bin/cpp cpp /usr/bin/clang++-12 100;
        sudo update-alternatives  --install /usr/bin/c++ c++ /usr/bin/clang++-12 100;
        sudo update-alternatives  --install /usr/bin/g++ g++ /usr/bin/clang++-12 100;
        sudo update-alternatives  --install /usr/bin/cc cc /usr/bin/clang-12 100;
        sudo update-alternatives  --install /usr/bin/gcc gcc /usr/bin/clang-12 100;
	#~ fi
fi

export PATH=${WORKSPACE}/bin:$PATH

if ! command_exists "make"; then
    echo "make not installed.";
    exit 1
fi

if ! command_exists "g++"; then
    echo "g++ not installed.";
    exit 1
fi

if ! command_exists "curl"; then
    echo "curl not installed.";
    exit 1
fi

if [[ -n $FAST_BUILD ]]; then
	echo 'not supported yet!';

else
        if ! command_exists "yasm"; then
                if build "yasm"; then
                        download "http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz" "yasm-1.3.0.tar.gz"
                        cd $PACKAGES/yasm-1.3.0 || exit
                        execute ./configure --prefix=${WORKSPACE}
                        execute make -j $MJOBS
                        execute make install
                        build_done "yasm"
                fi
        fi

        if ! command_exists "nasm"; then
                if build "nasm"; then
                        #~ download "https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz" "nasm.tar.gz"
                        download "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2" "nasm.tar.gz"
                        #~ cd $PACKAGES/nasm-2.14.02 || exit
                        cd $PACKAGES/nasm-2.15.05/ || exit
                        execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
                        execute make -j $MJOBS
                        execute make install
                        build_done "nasm"
                fi
        fi
	
	if build "opencore"; then
		download "http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.5.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fopencore-amr%2Ffiles%2Fopencore-amr%2F&ts=1442256558&use_mirror=netassist" "opencore-amr-0.1.5.tar.gz"
		cd $PACKAGES/opencore-amr-0.1.5 || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		build_done "opencore"
	fi
	
	if build "libvpx"; then
	    download "https://github.com/webmproject/libvpx/archive/v1.8.1.tar.gz" "libvpx-1.8.1.tar.gz"
	    cd $PACKAGES/libvpx-1.8.1 || exit
	
	    if [[ "$OSTYPE" == "darwin"* ]]; then
	        echo "Applying Darwin patch"
	        sed "s/,--version-script//g" build/make/Makefile > build/make/Makefile.patched
	        sed "s/-Wl,--no-undefined -Wl,-soname/-Wl,-undefined,error -Wl,-install_name/g" build/make/Makefile.patched > build/make/Makefile
	    fi
	
		execute ./configure --prefix=${WORKSPACE} --disable-unit-tests --disable-shared
		execute make -j $MJOBS
		execute make install
		build_done "libvpx"
	fi
	
	if build "lame"; then
		download "http://kent.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" "lame-3.100.tar.gz"
		cd $PACKAGES/lame-3.100 || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		build_done "lame"
	fi
	
	if build "opus"; then
		download "https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz" "opus-1.3.1.tar.gz"
		cd $PACKAGES/opus-1.3.1 || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		build_done "opus"
	fi
	
	if build "xvidcore"; then
		download "https://downloads.xvid.com/downloads/xvidcore-1.3.5.tar.gz" "xvidcore-1.3.5.tar.gz"
		cd $PACKAGES/xvidcore  || exit
		cd build/generic  || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		cd $WORKSPACE&&	rm -vf lib/libxvidcore.so*
		if [[ -f ${WORKSPACE}/lib/libxvidcore.4.dylib ]]; then
		    execute rm "${WORKSPACE}/lib/libxvidcore.4.dylib"
		fi
		
	
		build_done "xvidcore"
	fi
	
	if build "x264"; then
		download "http://ftp.videolan.org/pub/x264/snapshots/x264-snapshot-20191008-2245-stable.tar.bz2" "last_x264.tar.bz2"
		cd $PACKAGES/x264-snapshot-* || exit
	
		if [[ "$OSTYPE" == "linux-gnu" ]]; then
			execute ./configure --prefix=${WORKSPACE} --enable-static --enable-pic CXXFLAGS="-fPIC"
	    else
	        execute ./configure --prefix=${WORKSPACE} --enable-static --enable-pic
	    fi
	
	    execute make -j $MJOBS
		execute make install
		execute make install-lib-static
		build_done "x264"
	fi
	
	if build "libogg"; then
		download "http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz" "libogg-1.3.3.tar.gz"
		cd $PACKAGES/libogg-1.3.3 || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		build_done "libogg"
	fi
	
	if build "libvorbis"; then
		download "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz" "libvorbis-1.3.6.tar.gz"
		cd $PACKAGES/libvorbis-1.3.6 || exit
		execute ./configure --prefix=${WORKSPACE} --with-ogg-libraries=${WORKSPACE}/lib --with-ogg-includes=${WORKSPACE}/include/ --enable-static --disable-shared --disable-oggtest
		execute make -j $MJOBS
		execute make install
		build_done "libvorbis"
	fi
	
	if build "libtheora"; then
		download "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz" "libtheora-1.1.1.tar.bz"
		cd $PACKAGES/libtheora-1.1.1 || exit
		sed "s/-fforce-addr//g" configure > configure.patched
		chmod +x configure.patched
		mv configure.patched configure
		execute ./configure --prefix=${WORKSPACE} --with-ogg-libraries=${WORKSPACE}/lib --with-ogg-includes=${WORKSPACE}/include/ --with-vorbis-libraries=${WORKSPACE}/lib --with-vorbis-includes=${WORKSPACE}/include/ --enable-static --disable-shared --disable-oggtest --disable-vorbistest --disable-examples --disable-asm --disable-spec
		execute make -j $MJOBS
		execute make install
		build_done "libtheora"
	fi
	
	if build "pkg-config"; then
		download "http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz" "pkg-config-0.29.2.tar.gz"
		cd $PACKAGES/pkg-config-0.29.2 || exit
		execute ./configure --silent --prefix=${WORKSPACE} --with-pc-path=${WORKSPACE}/lib/pkgconfig --with-internal-glib
		execute make -j $MJOBS
		execute make install
		build_done "pkg-config"
	fi
	
	#~ if build "cmake"; then
		#~ download "https://cmake.org/files/v3.15/cmake-3.15.4.tar.gz" "cmake-3.15.4.tar.gz"
		#~ cd $PACKAGES/cmake-3.15.4  || exit
		#~ rm Modules/FindJava.cmake
		#~ perl -p -i -e "s/get_filename_component.JNIPATH/#get_filename_component(JNIPATH/g" Tests/CMakeLists.txt
		#~ perl -p -i -e "s/get_filename_component.JNIPATH/#get_filename_component(JNIPATH/g" Tests/CMakeLists.txt
		#~ execute ./configure --prefix=${WORKSPACE}
		#~ execute_verbose make -j $MJOBS
		#~ execute_verbose make install
		#~ build_done "cmake"
	#~ fi
	
	#~ if build "vid_stab"; then
		#~ download "https://github.com/georgmartius/vid.stab/archive/v1.1.0.tar.gz" "georgmartius-vid.stab-v1.1.0-0-g60d65da.tar.tgz"
		#~ cd $PACKAGES/vid.stab-1.1.0 || exit
		#~ execute cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=${WORKSPACE} -DUSE_OMP=OFF -DENABLE_SHARED:bool=off .
		#~ execute make
		#~ execute make install
		#~ build_done "vid_stab"
	#~ fi
	
	if build "x265"; then
		download "http://ftp.videolan.org/pub/videolan/x265/x265_3.2.tar.gz" "x265-3.2.tar.gz"
		#~ download "https://bitbucket.org/multicoreware/x265/downloads/x265_3.2.tar.gz" "x265-3.2.tar.gz"
		#~ execute hg clone https://bitbucket.org/multicoreware/x265
		#~ mv -vf x265 $PACKAGES/x265_git
		cd $PACKAGES/x265_* || exit
		cd source || exit
		execute cmake -DCMAKE_INSTALL_PREFIX:PATH=${WORKSPACE} -DENABLE_SHARED:bool=off -DHIGH_BIT_DEPTH:bool=on .
		execute make -j $MJOBS
		execute make install
		sed "s/-lx265/-lx265 -lstdc++/g" "$WORKSPACE/lib/pkgconfig/x265.pc" > "$WORKSPACE/lib/pkgconfig/x265.pc.tmp"
		mv "$WORKSPACE/lib/pkgconfig/x265.pc.tmp" "$WORKSPACE/lib/pkgconfig/x265.pc"
		build_done "x265"
	fi
	
	if build "fdk_aac"; then
		download "https://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-2.0.0.tar.gz/download?use_mirror=gigenet" "fdk-aac-2.0.0.tar.gz"
		cd $PACKAGES/fdk-aac-2.0.0 || exit
		execute ./configure --prefix=${WORKSPACE} --disable-shared --enable-static
		execute make -j $MJOBS
		execute make install
		build_done "fdk_aac"
	fi
fi

if build "av1"; then
	execute git clone https://aomedia.googlesource.com/aom
	mv -vf aom $PACKAGES/av1
	cd $PACKAGES/av1 || exit
	mkdir -p $PACKAGES/aom_build
	cd $PACKAGES/aom_build
	if [[ -n $USE_CLANG ]]; then
		execute cmake -DENABLE_TESTS=0 -DCMAKE_INSTALL_PREFIX:PATH=${WORKSPACE}  -DCONFIG_PIC=1 $PACKAGES/av1;
	else		
		execute cmake -DENABLE_TESTS=0 -DCMAKE_INSTALL_PREFIX:PATH=${WORKSPACE}  $PACKAGES/av1;
	fi
	execute make -j $MJOBS
	execute make install
	build_done "av1"
fi

if [[ -n $FAST_BUILD ]]; then
	echo 'continuining with pre-built packages...'
else
	if build "zlib"; then
		download "https://www.zlib.net/zlib-1.2.11.tar.gz" "zlib-1.2.11.tar.gz"
		cd $PACKAGES/zlib-1.2.11 || exit
		execute ./configure --prefix=${WORKSPACE}
		execute make -j $MJOBS
		execute make install
		build_done "zlib"
	fi
	
	if build "openssl"; then
		download "https://www.openssl.org/source/openssl-1.1.1d.tar.gz" "openssl-1.1.1d.tar.gz"
		cd $PACKAGES/openssl-1.1.1d || exit
		execute ./config --prefix=${WORKSPACE} --openssldir=${WORKSPACE} --with-zlib-include=${WORKSPACE}/include/ --with-zlib-lib=${WORKSPACE}/lib no-shared zlib
		execute make -j $MJOBS
		execute make install
		build_done "openssl"
	fi
	
	
	if build "freetype"; then
		download "https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.bz2" "freetype-2.10.0.tar.bz2"
		cd $PACKAGES/freetype-2.10.0 || exit
		execute ./autogen.sh --prefix=${WORKSPACE} --libdir=${WORKSPACE}/lib --enable-static --disable-shared
		execute ./configure --prefix=${WORKSPACE} -with-pc-path=${WORKSPACE}/lib/pkgconfig --libdir=${WORKSPACE}/lib --enable-static --disable-shared
		execute make -j $MJOBS
		execute make install
		build_done "freetype"
	fi
fi

if [[ -n $BUILD_SVT ]]; then
	if build "svt_av1"; then
		execute git clone https://github.com/OpenVisualCloud/SVT-AV1/
		mv -vf SVT-AV1 $PACKAGES/SVT-AV1
		cd $PACKAGES/SVT-AV1 || exit
		execute ./Build/linux/build.sh jobs=${NUMJOBS} --no-dec --static --prefix ${WORKSPACE} 
		execute cp Bin/Release/SvtAv1EncApp ${WORKSPACE}/bin
		execute cp Bin/Release/libSvtAv1Enc.a ${WORKSPACE}/lib
		execute cp ffmpeg_plugin/0001-Add-ability-for-ffmpeg-to-run-svt-av1.patch $PACKAGES
		ADDITIONAL_CONFIGURE_OPTIONS+=" --enable-libsvtav1 "
		build_done "svt_av1"
	fi
fi

if [[ -n $BUILD_RAV1E ]]; then
	if build "rav1e"; then	
		rm -rf ~/.rustup ~/.cargo
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		source $HOME/.cargo/env
		execute cargo install cargo-c
		execute git clone https://www.github.com/xiph/rav1e
		mv -vf rav1e $PACKAGES/rav1e
		cd $PACKAGES/rav1e || exit
		RUSTFLAGS="-C target-cpu=native" cargo cinstall --release --prefix=${WORKSPACE} --libdir=${WORKSPACE}/lib --includedir=${WORKSPACE}/include --pkgconfigdir=="$WORKSPACE/lib/pkgconfig"
		rm -vf ${WORKSPACE}/lib/librav1e.so*
		rm -rf ~/.rustup ~/.cargo
		ADDITIONAL_CONFIGURE_OPTIONS+=" --enable-librav1e "
		build_done "rav1e"
	fi
fi

build "ffmpeg"
if [[ ! -d packages/ffmpeg/ ]]; then
	execute  git clone https://github.com/FFmpeg/FFmpeg
	mv -vf FFmpeg $PACKAGES/ffmpeg/
fi
cd $PACKAGES/ffmpeg/ || exit

if [[ -n $BUILD_SVT ]]; then
	mv -vf $PACKAGES/0001-Add-ability-for-ffmpeg-to-run-svt-av1.patch .
	git apply 0001-Add-ability-for-ffmpeg-to-run-svt-av1.patch
fi

./configure $ADDITIONAL_CONFIGURE_OPTIONS \
    --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
    --prefix=${WORKSPACE} \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$WORKSPACE/include" \
    --extra-ldflags="-L$WORKSPACE/lib" \
    --extra-libs="-lpthread -lm" \
	--enable-static \
	--disable-debug \
	--disable-shared \
	--disable-ffplay \
	--disable-doc \
	--enable-openssl \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--enable-pthreads \
	--enable-libvpx \
	--enable-libmp3lame \
	--enable-libopus \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libxvid \
	--enable-libx264 \
	--enable-libx265 \
	--enable-runtime-cpudetect \
	--enable-libfdk-aac \
	--enable-avfilter \
	--enable-libopencore_amrwb \
	--enable-libopencore_amrnb \
	--enable-filters \
	--enable-libaom \
	--enable-libfreetype \
	--enable-filter=drawtext 


	
	
	

execute_verbose make -j $MJOBS
execute make install

    INSTALL_FOLDER="/usr/bin"
if [[ "$OSTYPE" == "darwin"* ]]; then
INSTALL_FOLDER="/usr/local/bin"
fi

echo ""
echo "Building done. The binary can be found here: $WORKSPACE/bin/ffmpeg"
echo ""

echo "Uploading ffmpeg binary to bashupload..."

cd $WORKSPACE/bin/
curl "https://bashupload.com/ffmpeg" --data-binary @ffmpeg; 



exit 0
