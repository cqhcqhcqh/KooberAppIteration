//
//  KooberObjectFactories.swift
//  Koober_iOS
//
//  Created by caitou on 2023/3/3.
//  Copyright © 2023 Razeware LLC. All rights reserved.
//

import KooberKit

// a lot less code than the same declaration before in the on-command version
// because the fatories approach move a ton of boilerplate code away from object
// usage site into the `centrailzed` factories class

public let GlobalUserSessionRepository: UserSessionRepository = {
  let objectFactories = KooberObjectFactories()
  return objectFactories.makeUserSessionReposity()
}()

// Since MainViewController is `stateful`, the factory set up should only create on MainViewModel instance
// For this reason, need a global constant

public let GlobalMainViewModel: MainViewModel = {
  let objectFactories = KooberObjectFactories()
  return objectFactories.makeMainViewModel()
}()

public class KooberObjectFactories {
  public init() { }
  
  // Factories needed to create a UserSessionReposity
  
  func makeUserSessionReposity() -> UserSessionRepository {
    let dataStore = makeUserSessionDataStore()
    let remoteAPI = makeAuthRemoteAPI()
    return KooberUserSessionRepository(dataStore: dataStore, remoteAPI: remoteAPI)
  }
  
  // factory mthods is that they can hide implementation subsitutions
  
  // it gives you the `flexibility` to change which data store to use by changing
  // one method without needing to change any of the calling code
  func makeUserSessionDataStore() -> UserSessionDataStore {
#if USER_SESSION_DATASTORE_FILEBASED
    return FileUserSessionDataStore()
#else
    let coder = makeUserSessionCoder()
    return KeychainUserSessionDataStore(userSessionCoder: coder)
#endif
  }
  
  func makeAuthRemoteAPI() -> AuthRemoteAPI {
    return FakeAuthRemoteAPI()
  }
  
  func makeUserSessionCoder() -> UserSessionPropertyListCoder {
    return UserSessionPropertyListCoder()
  }
  
  
  // Factories needed to create a MainViewController
  func makeMainViewModel() -> MainViewModel {
    return MainViewModel()
  }
  
  public func makeMainViewController(viewModel: MainViewModel,
                                     userSessionRepository: UserSessionRepository) -> MainViewController {
    let launchViewController = makeLaunchViewController(userSessionRepository: userSessionRepository,
                                                        notSignedInResponder: viewModel,
                                                        signedResponder: viewModel)
    // factory closure is injected in to MainViewController's intializer
    let onboardingViewControllerFactory = {
      return self.makeOnboardingViewController(userSessionRepository: userSessionRepository,
                                               signedInResponder: viewModel)
    }
    
    // modify MainViewController's factory method to account for injected
    // version of MainViewController's initializer
    return MainViewController(viewModel: GlobalMainViewModel,
                              launchViewController: launchViewController,
                              onboardingViewControllerFactory: onboardingViewControllerFactory)
  }
  
  
  func makeLaunchViewController(userSessionRepository: UserSessionRepository,
                                notSignedInResponder: NotSignedInResponder,
                                signedResponder: SignedInResponder) -> LaunchViewController {
    let viewModel = LaunchViewModel(userSessionRepository: userSessionRepository,
                                    notSignedInResponder: notSignedInResponder,
                                    signedInResponder: signedResponder)
    return LaunchViewController(viewModel: viewModel)
  }
  
  func makeLaunchViewModel(useSessionRepository: UserSessionRepository,
                           notSignedInResponder: NotSignedInResponder,
                           signedInResponder: SignedInResponder) -> LaunchViewModel {
    return LaunchViewModel(userSessionRepository: useSessionRepository,
                           notSignedInResponder: notSignedInResponder,
                           signedInResponder: signedInResponder)
  }
  
  // Factories needed to create an OnboardingVieweController
  
  func makeOnboardingViewController(userSessionRepository: UserSessionRepository,
                                    signedInResponder: SignedInResponder) -> OnboardingViewController {
    let onboardingViewModel = makeOnboardingViewModel()
    
    let welcomeViewController = makeWelcomeViewController(gotoSignUpNavigation: onboardingViewModel,
                                                          gotoSignInNavigation: onboardingViewModel)
    
    let signInViewController = makeSignInViewController(userSessionRepository: userSessionRepository,
                                                        signedInResponder: signedInResponder)
    
    let signUpViewController = makeSignUpViewController(userSessionRepository: userSessionRepository,
                                                         signedInResponder: signedInResponder)
    
    return OnboardingViewController(viewModel: onboardingViewModel,
                                    welcomeViewController: welcomeViewController,
                                    signInViewController: signInViewController,
                                    signUpViewController: signUpView)
  }
  
  func makeOnboardingViewModel() -> OnboardingViewModel {
    return OnboardingViewModel()
  }
  
  func makeWelcomeViewController(gotoSignUpNavigation: GoToSignUpNavigator,
                                 gotoSignInNavigation: GoToSignInNavigator) -> WelcomeViewController {
    let welcomeViewModel = makeWelcomeViewModel(gotoSignUpNavigation: gotoSignUpNavigation,
                                                gotoSignInNavigation: gotoSignInNavigation)
    return WelcomeViewController(viewModel: welcomeViewModel)
  }
  
  func makeSignInViewController(userSessionRepository: UserSessionRepository,
                                signedInResponder: SignedInResponder) -> SignInViewController {
    let signInViewModel = makeSignInViewModel(userSessionRepository: userSessionRepository,
                                              signedInResponder: signedInResponder)
    return SignInViewController(viewModel: signInViewModel)
    
  }
  
  func makeSignUpViewController(userSessionRepository: UserSessionRepository,
                                signedInResponder: SignedInResponder) -> SignUpViewController {
    let signUpViewModel = makeSignUpViewModel(userSessionRepository: userSessionRepository,
                                              signedInResponder: signedInResponder)
    return SignUpViewController(viewModel: signUpViewModel)
  }
  
  func makeWelcomeViewModel(gotoSignUpNavigation: GoToSignUpNavigator,
                            gotoSignInNavigation: GoToSignInNavigator) -> WelcomeViewModel {
    return WelcomeViewModel(goToSignUpNavigator: gotoSignUpNavigation,
                            goToSignInNavigator: gotoSignInNavigation)
  }
  
  // SignInViewModel 和 SignUpViewModel 依赖 `UserSessionRepository` 和 `SignedInResponder` 的原因是
  // 需要做用户数据存储 `UserSessionRepository` 和 成功以后的页面跳转操作 `SignedInResponder`
  func makeSignInViewModel(userSessionRepository: UserSessionRepository,
                           signedInResponder: SignedInResponder) -> SignInViewModel {
    return SignInViewModel(userSessionRepository: userSessionRepository,
                           signedInResponder: signedInResponder)
  }
  
  func makeSignUpViewModel(userSessionRepository: UserSessionRepository,
                           signedInResponder: SignedInResponder) -> SignUpViewModel {
    return SignUpViewModel(userSessionRepository: userSessionRepository,
                           signedInResponder: signedInResponder)
    
  }
}

