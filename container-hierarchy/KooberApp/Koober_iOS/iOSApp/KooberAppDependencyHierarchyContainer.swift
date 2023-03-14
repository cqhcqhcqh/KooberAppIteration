//
//  KooberAppDependencyHierarchyContainer.swift
//  Koober_iOS
//
//  Created by caitou on 2023/3/14.
//  Copyright © 2023 Razeware LLC. All rights reserved.
//

import KooberKit

 /// KooberObjectFactories needes to go from being stateless to being stateful
 /// So use the container to hold onto long-lived dependencies（sharedUserSessionRepository/sharedMainViewModel）
public class KooberAppDependencyHierarchyContainer {
  
  let sharedUserSessionRepository: UserSessionRepository
  
  /// give the container the aiblity to create a MainViewController
  /// 因为`MainViewController`是依赖`MainViewModel`的
  /// 而且很多功能也依赖这个对象
  /// 最重要的是这个对象的生命周期跟 MainViewController 一样
  let sharedMainViewModel: MainViewModel
  
 /// Because MainViewModel 's initializer has no parameters,
 /// so don't need this inline factory method
 /// Can also decalare property like this
 /// let sharedMainViewModel = MainViewModel()
  
  public init() {
    /// 使用这种 inline facotry 函数（而不是成员函数）来构建成员变量的原因是因为 Swift 的构造方法中
    /// 在初始化所有的成员之前，不能使用 `self` 来调用成员函数
    func makeUserSessionRepository() -> UserSessionRepository {
      let dataStore = makeUserSessionDataStore()
      let remoteAPI = makeAuthRemoteAPI()
      return KooberUserSessionRepository(dataStore: dataStore,
                                         remoteAPI: remoteAPI)
    }
    
    /// 和 factories-version 不同的是，下面所有的这些工厂方法都没有参数
    /// 因为factories 是无状态的，内部无法持有 long-live dependencies，而 single-container 就可以做到
    /// 这样就将工厂方法的外部依赖都放到内部持有，从而简化了工厂方法
    /// 同时不同的工厂方法之间也可以相互调用，相互调用的时候也不需传递参数
    /// Container 拥有一切可以构建整个 dependency graph 的依赖
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
    
    func makeUserSessionCoder() -> UserSessionCoding {
      return UserSessionPropertyListCoder()
    }
    
    func makeMainViewModel() -> MainViewModel {
      return MainViewModel()
    }
    
    sharedUserSessionRepository = makeUserSessionRepository()
    sharedMainViewModel = makeMainViewModel()
  }
  
  
  func makeOnBoardingViewController() -> OnboardingViewController {
    /// Single-container version
//    self.sharedOnboardingViewModel = makeOnboardingViewModel()
//
//    let welcomeViewController = makeWelcomeViewController()
//    let signInViewController = makeSignInViewController()
//    let signUpViewController = makeSignUpViewController()
//
//    return OnboardingViewController(viewModel: self.sharedOnboardingViewModel!,
//                                    welcomeViewController: welcomeViewController,
//                                    signInViewController: signInViewController,
//                                    signUpViewController: signUpViewController)
//  }
//
//  func makeOnboardingViewModel() -> OnboardingViewModel {
//    return OnboardingViewModel()
//  }
//
//  func makeWelcomeViewController() -> WelcomeViewController {
//    let viewModel = makeWelcomeViewModel()
//    return WelcomeViewController(viewModel: viewModel)
//  }
//
//  func makeSignInViewController() -> SignInViewController {
//    let viewModel = makeSignInViewModel()
//    return SignInViewController(viewModel: viewModel)
//  }
//
//  func makeSignUpViewController() -> SignUpViewController {
//    let viewModel = makeSignUpViewModel()
//    return SignUpViewController(viewModel: viewModel)
//  }
//
//  func makeWelcomeViewModel() -> WelcomeViewModel {
//    return WelcomeViewModel(goToSignUpNavigator: sharedOnboardingViewModel!,
//                            goToSignInNavigator: sharedOnboardingViewModel!)
//  }
//
//  func makeSignInViewModel() -> SignInViewModel {
//    return SignInViewModel(userSessionRepository: sharedUserSessionRepository,
//                           signedInResponder: sharedMainViewModel)
//  }
//
//  func makeSignUpViewModel() -> SignUpViewModel {
//    return SignUpViewModel(userSessionRepository: sharedUserSessionRepository,
//                           signedInResponder: sharedMainViewModel)
//  }
//
    /// 每次都创建一个新的 `KooberOnboardingDependencyScopedContainer`
    /// 在 HierarchyContainer 眼里，KooberOnboardingDependencyScopedContainer 就是一个 factories，也就是 stateless
    let onboardingDependencyContainer = KooberOnboardingDependencyScopedContainer(appDependencyContainer: self)
    return onboardingDependencyContainer.makeOnboardingViewController()
  }
  
  func makeLanunchViewController() -> LaunchViewController {
    let viewModel = makeLaunchViewModel()
    return LaunchViewController(viewModel: viewModel)
  }
  
  func makeLaunchViewModel() -> LaunchViewModel {
    return LaunchViewModel(userSessionRepository: sharedUserSessionRepository,
                           notSignedInResponder: sharedMainViewModel,
                           signedInResponder: sharedMainViewModel)
  }
  
  public func makeMainViewController() -> MainViewController {
    let lanunchViewController = makeLanunchViewController()
    
    let onboardingViewConotrollerFactory = {
      return self.makeOnBoardingViewController()
    }
    
    return MainViewController(viewModel: sharedMainViewModel,
                              launchViewController: lanunchViewController,
                              onboardingViewControllerFactory: onboardingViewConotrollerFactory)
  }
}
