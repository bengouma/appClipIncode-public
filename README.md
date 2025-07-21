# Integrating IDDataWeb service with Incode IOS SDK
## Prerequisites 
* IDDataWeb Incode BioGovID service API key and client secret
* API key and Client Secret of yhour BioGovID service
* IDDataWeb account setup to use the Admin API
* CocoaPod installed
* Access to the [Incode-Technologies-Example-Repos/IncdDistributionPodspecs](https://github.com/Incode-Technologies-Example-Repos/IncdDistributionPodspecs) and IncodeTechnologies/IncdOnboarding-distribution repos 
  * SSH authentication with Git is required to be setup on your mac
* Incode iOS SDK installed

**Note:** The Incode iOS SDK is based off of the UIKit development environment so your app will need to be setup to use it as well

## Getting access to SDK repos
In order to be able to install the Incode iOS SDK, you need access to the [Incode-Technologies-Example-Repos/IncdDistributionPodspecs](https://github.com/Incode-Technologies-Example-Repos/IncdDistributionPodspecs) and IncodeTechnologies/IncdOnboarding-distribution repos in Github. To gain access, send an email to support@incode.com that explains which repos you would like access to and your Github username. They will reply once they have granted you access to the repos.

## Installing the Incode iOS SDK
### Installing via CocoaPods
* In the root of your repo, created a file named Podfile

For more detailed installation instructions, refer to the official Incode SDK Installation [documentation](https://developer.incode.com/docs/manual-installation)

## Integrating the Incode SDK with your app

### Finding your Incode API key and Config ID
Before we utilize the IncdOnbaording framework in our app, we will need to find the Incode API key and Config ID our service uses sowe can provide them to the Incode API. To find this information, follow these steps:
* Navigate to your Incode verification service in the AXN Admin Console
* In your verification service's settings, select the "Attribute Providers" tab at the top and then open the "Properties" tab below
* Here you will find the Incode API key and Config ID that you will need when integrating the Incode SDK to your app
  * << Image of service details >>

### AppDelegate
In your AppDelegate, we will need to initialize the IncdOnboarding object during launch.
* Import the `IncdOnboarding` framework
* In your `didFinishLaunchingWithOptions` application function, initialize the IncdOnboarding object with this line of code:
  * `IncdOnboardingManager.shared.initIncdOnboarding(url: "https://saas-api.incodesmile.com", apiKey: "<< your_incode_api_key ")`

### ViewController
Once the IncdOnboarding object is initialized, we will define a few functions in the ViewController to configure our flow and start the Incode Onbaording flow.
* Import the `IncdOnboarding` framework
