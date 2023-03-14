//
//  KooberOnboardingDependencyScopedContainer.swift
//  Koober_iOS
//
//  Created by caitou on 2023/3/14.
//  Copyright © 2023 Razeware LLC. All rights reserved.
//

import KooberKit

class KooberOnboardingDependencyScopedContainer {
  /// propeties from parent container
  /// 而不是直接支持一个指向 parent container 的引用
  let sharedUserSessionRepository: UserSessionRepository
  let sharedMainViewModel: MainViewModel
  
  // 这个 viewModel 在 on boarding scope 的角度来看
  // 其声明周期就是一个 long-lived 的（this long-lived dependency only live as long as this container lives）
  // this property is a constant and not optional
  // 从 Appcontainer scope 的角度来看就是临时的（可选属性）
  let sharedOnboardingViewModel: OnboardingViewModel
  
  // container's initializer
  init(appDependencyContainer: KooberAppDependencyHierarchyContainer) {
    /// linle factory method to createss a shared onboardingViewModel
    func makeOnboardingViewModel() -> OnboardingViewModel {
      return OnboardingViewModel()
    }
    
    /// because it is statefule
    /// therefore needs to be stored in a property
    sharedOnboardingViewModel = makeOnboardingViewModel()
    
    /// Holding dependencies from a parent container is OK
    /// because parent container outlive child containers
  
    sharedUserSessionRepository = appDependencyContainer.sharedUserSessionRepository
    sharedMainViewModel = appDependencyContainer.sharedMainViewModel
  }
  
  /// Factories needed to create an OnboardingViewController
  
  func makeOnboardingViewController() -> OnboardingViewController {
    let welcomeViewController = makeWelcomeViewController()
    let signInViewController = makeSignInViewController()
    let signUpViewController = makeSignUpViewController()
    return OnboardingViewController(viewModel: sharedOnboardingViewModel,
                                    welcomeViewController: welcomeViewController,
                                    signInViewController: signInViewController,
                                    signUpViewController: signUpViewController)
  }
  
  func makeWelcomeViewController() -> WelcomeViewController {
    let viewModel = makeWelcomeViewModel()
    return WelcomeViewController(viewModel: viewModel)
  }
  
  func makeSignInViewController() -> SignInViewController {
    let viewModel = makeSignInViewModel()
    return SignInViewController(viewModel: viewModel)
  }
  
  func makeSignUpViewController() -> SignUpViewController {
    let viewModel = makeSignUpViewModel()
    return SignUpViewController(viewModel: viewModel)
  }
  
  func makeWelcomeViewModel() -> WelcomeViewModel {
    return WelcomeViewModel(goToSignUpNavigator: sharedOnboardingViewModel,
                            goToSignInNavigator: sharedOnboardingViewModel)
  }
  
  func makeSignInViewModel() -> SignInViewModel {
    return SignInViewModel(userSessionRepository: sharedUserSessionRepository,
                           signedInResponder: sharedMainViewModel)
  }
  
  func makeSignUpViewModel() -> SignUpViewModel {
    return SignUpViewModel(userSessionRepository: sharedUserSessionRepository,
                           signedInResponder: sharedMainViewModel)
  }
}
