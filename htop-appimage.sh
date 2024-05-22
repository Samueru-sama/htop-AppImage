#!/bin/sh

APP=htop
APPDIR="$APP".AppDir
SITE="htop-dev/htop"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD HTOP
CURRENTDIR="$(dirname "$(readlink -f "$0")")" # DO NOT MOVE THIS
version=$(wget -q https://api.github.com/repos/$SITE/releases -O - | sed 's/[()",{}]/ /g; s/ /\n/g' | grep -o 'https.*releases.*htop.*tar.xz' | head -1)
wget "$version" && tar fx ./*tar* && cd ./htop* && ./autogen.sh && ./configure --prefix="$CURRENTDIR" --enable-sensors --enable-static \
&& make && make install && cd .. && rm -rf ./htop* ./*tar* || exit 1

# PREPARE APPIMAGE
#cp ./share/applications/*.desktop ./ && cp ./share/icons/*/*/*/* ./htop.svg && ln -s ./htop.svg ./.DirIcon || exit 1 # Causes a sigsegv with appimagetool
cp ./share/applications/*.desktop ./ && cp ./share/pixmaps/* ./htop.png && ln -s ./htop.png ./.DirIcon || exit 1 # Doesn't cause the sigsegv.

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
"$CURRENTDIR/bin/htop" "$@"
EOF
chmod a+x ./AppRun

APPVERSION=$(./AppRun -V | awk '{print $2}')
if [ -z "$APPVERSION" ]; then echo "Failed to get version from htop"; exit 1; fi

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')
wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR"
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf ./"$APP"
echo "All Done!"
