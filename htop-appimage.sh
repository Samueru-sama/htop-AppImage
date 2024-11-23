#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APP=htop
APPDIR="$APP".AppDir
SITE="htop-dev/htop"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"

# CREATE DIRECTORIES
mkdir -p ./"$APP"/AppDir
cd ./"$APP"/AppDir

# DOWNLOAD AND BUILD HTOP
CURRENTDIR="$(dirname "$(readlink -f "$0")")" # DO NOT MOVE THIS
HTOP_URL=$(wget -q https://api.github.com/repos/$SITE/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi 'https.*releases.*htop.*tar.xz' | head -1)

wget "$HTOP_URL"
tar fx ./*.tar.*

cd ./htop*
./autogen.sh
./configure --prefix="$CURRENTDIR" --enable-sensors --enable-static
make
make install
cd ..
rm -rf ./htop* ./*.tar.*

# PREPARE APPIMAGE
cp ./share/applications/*.desktop ./
cp ./share/pixmaps/* ./htop.png
ln -s ./htop.png ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/usr/bin/env sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
"$CURRENTDIR"/bin/htop "$@"
EOF
chmod +x ./AppRun
VERSION="$(./AppRun -V | awk '{print $2}')"

# MAKE APPIMAGE
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage
mv ./*.AppImage* ..
rm -rf ./"$APP"
echo "All Done!"
