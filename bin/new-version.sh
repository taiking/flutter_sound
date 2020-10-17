#!/bin/bash
if [ -z "$1" ]; then
        echo "Correct usage is $0 <Version> [SONATYPE | BINTRAY]"
        exit -1
fi


if [ -z "$2" ]; then
        SONATYPE=0
        BINTRAY=1
else
        if [[] $2  = "BINTRAY" ]; then
                SONATYPE=0
                BINTRAY=1
        elif [[ $2  = "SONATYPE" ]]; then
                SONATYPE=1
                BINTRAY=0
        else
                echo "Correct usage is $0 <Version> [SONATYPE | BINTRAY]"
                exit -1
        fi
fi


VERSION=$1
VERSION_CODE=${VERSION//./}
VERSION_CODE=${VERSION_CODE//+/}


gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/" flauto_engine_ios.podspec
gsed -i  "s/^\( *s.dependency *'flauto_engine_ios', *\).*$/\1'$VERSION'/" flutter_sound/ios/flutter_sound.podspec
gsed -i  "s/^\( *versionName *\).*$/\1'$VERSION'/" flauto_engine/android/FlautoEngine/build.gradle
gsed -i  "s/^\( *versionCode *\).*$/\11$VERSION_CODE/" flauto_engine/android/FlautoEngine/build.gradle
gsed -i  "s/^\( *implementation 'xyz.canardoux:FlautoEngine:\).*$/\1$VERSION'/" flutter_sound/android/build.gradle
gsed -i  "s/^\( *s.version *= *\).*$/\1'$VERSION'/" flutter_sound/ios/flutter_sound.podspec
gsed -i  "s/^\( *version *\).*$/\1'$VERSION'/" flutter_sound/android/build.gradle
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/" flutter_sound/pubspec.yaml
gsed -i  "s/^\( *flutter_sound_platform_interface: *\).*$/\1$VERSION/" flutter_sound/pubspec.yaml
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/" flutter_sound/example/pubspec.yaml
gsed -i  "s/^\( *## \).*$/\1$VERSION/" flutter_sound/CHANGELOG.md
gsed -i  "s/^\( *## \).*$/\1$VERSION/" flutter_sound_platform_interface/CHANGELOG.md
gsed -i  "s/^\( *version: *\).*$/\1$VERSION/" flutter_sound_platform_interface/pubspec.yaml

cd flutter_sound
#flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


cd flutter_sound_platform_interface/
#flutter pub publish
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi
cd ..


git add .
git commit -m "FLAUTO : Version $VERSION"
git push
git tag -f $1
git push --tag -f

pod cache clean --all
pod trunk push flauto_engine_ios.podspec
if [ $? -ne 0 ]; then
    echo "Error"
    exit -1
fi


cd flauto_engine/android/FlautoEngine
if [ $BINTRAY .eq 1 ]; then

        #./gradlew clean
        #./gradlew assemble
        #if [ $? -ne 0 ]; then
        #    echo "Error"
        #    exit -1
        #fi

        ./gradlew clean build publishReleasePublicationToSonatypeRepository
        if [ $? -ne 0 ]; then
            echo "Error"
            exit -1
        fi

        #./gradlew closeAndReleaseRepository
        #if [ $? -ne 0 ]; then
        #    echo "Error"
        #    exit -1
        #fi

else
        ./gradlew clean build bintrayUpload
        if [ $? -ne 0 ]; then
            echo "Error"
            exit -1
        fi

fi
cd ../../..


if [ $BINTRAY .eq 1 ]; then
        echo 'E.O.J'
        echo 'Do not forget to go to "https://oss.sonatype.org/#view-repositories;public~browsestorage" and close/publish your new version'
else
        echo 'E.O.J'
        echo 'Do not forget to go to "https://bintray.com/larpoux/CanardouxMaven/xyz.canardoux.FlautoEngine" and close/publish your new version'
fi