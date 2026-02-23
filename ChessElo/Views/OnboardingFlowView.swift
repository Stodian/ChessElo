import SwiftUI

struct OnboardingFlowView: View {
    let onCompletion: () -> Void

    var body: some View {
        Text("Loading Onboarding...")
            .onAppear {
                onCompletion()
            }
    }
}




// import SwiftUI

// struct OnboardingFlowView: View {
//     @State private var currentStep = 1
//     let onCompletion: () -> Void

//     var body: some View {
//         VStack {
//             if currentStep == 1 {
//                 QuestionOne(onNext: { currentStep += 1 })
//             } else if currentStep == 2 {
//                 QuestionTwo(onNext: { currentStep += 1 })
//             } else if currentStep == 3 {
//                 QuestionThree(onNext: { currentStep += 1 })
//             } else if currentStep == 4 {
//                 QuestionFour(onNext: { currentStep += 1 })
//             } else if currentStep == 5 {
//                 QuestionFive(onNext: {
//                     onCompletion()
//                 })
//             }
//         }
//     }
// }
