#!/bin/sh

APP=htop
SITE="htop-dev/htop"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p "./$APP/tmp" "./$APP/src" "./$APP/$APP.AppDir/usr/bin" && cd "./$APP/tmp" || exit 1

# DOWNLOAD AND BUILD HTOP
version=$(wget -q https://api.github.com/repos/$SITE/releases -O - | grep browser_download_url | grep -i tar.xz | cut -d '"' -f 4 | head -1)
wget "$version" && tar fx ./*tar* && cd .. && mv --backup=t ./tmp/*/* ./src
cd ./src && ./autogen.sh && ./configure && make || exit 1

# PREPARE APPIMAGE
cd .. && mv ./src/htop "./$APP.AppDir/usr/bin" && mv ./src/*.png "./$APP.AppDir/$APP.png" && mv ./src/*.desktop "./$APP.AppDir/$APP.desktop"
cd "./$APP.AppDir" && ln -s "./$APP.png" ./.DirIcon || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR/usr/bin/htop" "$@"
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1)
wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP.AppDir
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }

APPNAME=$(ls *AppImage)
APPVERSION=$(echo $version | awk -F / '{print $(NF-1)}')
mv ./*AppImage ./"$APPVERSION"-"$APPNAME"
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf "./$APP"
echo "All Done!"
