#!/bin/bash
 
      export LC_ALL=en_US.UTF-8
      export LANG=en_US.UTF-8
      export LANGUAGE=en_US.UTF-8

      echo "IPAFileName:$IPAFileName"
      echo "IPAFileUrl:$IPAFileUrl"
      echo "AppleId:$AppleId"
      echo "BundleId:$BundleId"
      echo "AppleUserName:$AppleUserName"
      echo "ApplicationSpecificPassword:$ApplicationSpecificPassword"
      echo "AppStoreConnectApiKey:$AppStoreConnectApiKey"
      echo "AppStoreConnectApiKeyFileName:$AppStoreConnectApiKeyFileName"
      echo "appleStoreSubmitApiType:$appleStoreSubmitApiType"
      
      locale
      curl -o "./$IPAFileName" -k $IPAFileUrl
      #cat "./$IPAFileName"
      
      curl -O https://appcircle-common.s3-eu-west-1.amazonaws.com/apple/iTMSTransporter-2.1.0.pkg
      sudo installer -pkg iTMSTransporter-2.1.0.pkg -target /
      sudo chown -R $(whoami): /usr/local/itms
          
      if [ $appleStoreSubmitApiType == 0 || $appleStoreSubmitApiType=="ApplicationSpecificPasswordConnection" ]   #ApplicationSpecificPasswordConnection
      then
      
        mkdir filename.itmsp

        mv ./$IPAFileName "filename.itmsp/$IPAFileName"

        #stat -f %z "filename.itmsp/$IPAFileName"
        fileSize=`stat -f %z "filename.itmsp/$IPAFileName"`
        
        #find -s "filename.itmsp/$IPAFileName" -type f -exec md5 -q {} \;
        md5Checksum=`find -s "filename.itmsp/$IPAFileName" -type f -exec md5 -q {} \;`
        #echo $md5Checksum
        
        bundleIdentifier=$BundleId
        appleId="$AppleId"

        dir="/usr/local/itms/bin"
        workDir=`pwd`

        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > filename.itmsp/metadata.xml
        echo "<package xmlns=\"http://apple.com/itunes/importer\" version=\"software5.4\">" >> filename.itmsp/metadata.xml
        echo "    <software_assets bundle_identifier=\"$bundleIdentifier\" apple_id=\"$appleId\" app_platform=\"ios\">" >> filename.itmsp/metadata.xml
        echo "        <asset type=\"bundle\">" >> filename.itmsp/metadata.xml 
        echo "        	<data_file>" >> filename.itmsp/metadata.xml
        echo "                <size>$fileSize</size>" >> filename.itmsp/metadata.xml 
        echo "                <file_name>$IPAFileName</file_name>" >> filename.itmsp/metadata.xml 
        echo "            	  <checksum type=\"md5\">$md5Checksum</checksum>" >> filename.itmsp/metadata.xml
        echo "          </data_file>" >> filename.itmsp/metadata.xml 
        echo "        </asset>" >> filename.itmsp/metadata.xml
        echo "    </software_assets>" >> filename.itmsp/metadata.xml 
        echo "</package>" >> filename.itmsp/metadata.xml
        
        #cat filename.itmsp/metadata.xml
        
        destinationDir=$workDir"/filename.itmsp"
        #echo $destinationDir
        
        if [ $StackType == 10 ] #TestFlight
        then
          #echo $dir/iTMSTransporter -m upload -u "$AppleUserName" -p "$ApplicationSpecificPassword" -f "$destinationDir" -k 100000 -v eXtreme

          sudo $dir/iTMSTransporter -m upload -u "$AppleUserName" -p "$ApplicationSpecificPassword" -f "$destinationDir" -k 100000 -v eXtreme
          
          if [ $? -eq 0 ]
          then
            echo "TestFlight progress succeeded"
            exit 0
          else
            echo "TestFlight progress failed :" >&2
            exit 1
          fi
        fi
        if [ $StackType == 12 ] #Release
        then
          #echo $dir/iTMSTransporter -m upload -u "$AppleUserName" -p "$ApplicationSpecificPassword" -f "$destinationDir" -k 100000 -v eXtreme

          sudo $dir/iTMSTransporter -m upload -u "$AppleUserName" -p "$ApplicationSpecificPassword" -f "$destinationDir" -k 100000 -v eXtreme
          
          if [ $? -eq 0 ] 
          then
            echo "Release progress succeeded"
            exit 0
          else
            echo "Release progress failed :" >&2
            exit 1
          fi
        fi
      fi
      
      if [ $appleStoreSubmitApiType == 1 || $appleStoreSubmitApiType=="AppStoreConnectApiConnection" ]   #AppStoreConnectApiConnection
      then
        #gem install fastlane -NV
        if [[ "$AC_XCODE_VERSION" == "13."* ]];
            then
            export ITMSTRANSPORTER_FORCE_ITMS_PACKAGE_UPLOAD=true
        fi
        bundle init
        echo "gem \"fastlane\"">>Gemfile
        bundle install
        mkdir fastlane
        touch fastlane/Appfile
        touch fastlane/Fastfile
        mv $FastFileConfig "fastlane/Fastfile"
        #cat fastlane/Fastfile

        mv "$AppStoreConnectApiKey" "$AppStoreConnectApiKeyFileName"
        #cat "$AppStoreConnectApiKeyFileName"

        if [ $StackType == 10 ]
        then
          bundle exec fastlane doTestFlight --verbose
          if [ $? -eq 0 ]
          then
            echo "TestFlight progress succeeded"
            exit 0
          else
            echo "TestFlight progress failed :" >&2
            exit 1
          fi
        fi
        if [ $StackType == 12 ]
        then
          bundle exec fastlane doRelease --verbose
          if [ $? -eq 0 ] 
          then
            echo "Release progress succeeded"
            exit 0
          else
            echo "Release progress failed :" >&2
            exit 1
          fi
        fi
      fi
