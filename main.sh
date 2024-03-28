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
       
     if [ "$appleStoreSubmitApiType" == 1 ] || [ "$appleStoreSubmitApiType" == "AppStoreConnectApiConnection" ]; then
 
        bundle init
        echo "gem \"fastlane\"">>Gemfile
        bundle install
        mkdir fastlane
        touch fastlane/Appfile
        touch fastlane/Fastfile
        mv $FastFileConfig "fastlane/Fastfile"

        mv "$AppStoreConnectApiKey" "$AppStoreConnectApiKeyFileName"

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
