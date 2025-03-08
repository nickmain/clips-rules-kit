// Copyright (c) 2025 David N Main

import CLIPSCore
import CLIPSCoreHelpers

// typedef void VoidCallFunctionWithArg(Environment *,void *,void *);
//
// struct callFunctionItemWithArg *ListOfAssertFunctions;
// struct callFunctionItemWithArg *ListOfRetractFunctions;
// ModifyCallFunctionItem *ListOfModifyFunctions;

//struct callFunctionItemWithArg
//  {
//   const char *name;
//   VoidCallFunctionWithArg *func;
//   int priority;
//   struct callFunctionItemWithArg *next;
//   void *context;
//  };

fileprivate func clipsFactAssertCallback(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?,
                                         _ factPtr: UnsafeMutableRawPointer?,
                                         _ contextPtr: UnsafeMutableRawPointer?) {
    guard let envPtr,
          let environment = CLIPS.Engine.from(envPtr)?.environment,
          let factPtr = factPtr?.assumingMemoryBound(to: CLIPSCore.Fact.self)
    else { return }

    environment.assertCallback(factPtr: factPtr)
}

fileprivate func createUserData(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?) -> UnsafeMutableRawPointer? {
    print("🟡 createUserData")
    let userDataPtr = Unmanaged.passRetained(UserData()).toOpaque()
    let swiftUserData = UnsafeMutablePointer<SwiftUserData>.allocate(capacity: 1)
    swiftUserData.pointee.instance = userDataPtr
    return UnsafeMutableRawPointer(swiftUserData)
}

fileprivate func deleteUserData(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?, _ userDataPtr: UnsafeMutableRawPointer?) {
    print("🟡 deleteUserData enter")
    guard let userDataPtr = userDataPtr?.assumingMemoryBound(to: SwiftUserData.self) else { return }

    Unmanaged<UserData>.fromOpaque(userDataPtr.pointee.instance).release()
    print("🟡 deleteUserData exit")
}

fileprivate var theUserDataRecord = userDataRecord(dataID: 0,
                                                   createUserData: createUserData,
                                                   deleteUserData: deleteUserData)

class UserData {
    var message = "Jello world"

    deinit {
        print("❌ UserData deinit")
    }
}

extension CLIPS.Environment {

    func registerFactCallbacks() {
        let assertNamePtr = retainCStringPtr(from: "assertCallback")
        let retractNamePtr = retainCStringPtr(from: "retractCallback")
        let modifyNamePtr = retainCStringPtr(from: "modifyCallback")
        CLIPSCore.AddAssertFunction(ptr, assertNamePtr, clipsFactAssertCallback, 0, nil)
    }

    func installUserDataRecord() {
        CLIPSCore.InstallUserDataRecord(ptr, &theUserDataRecord)

        print("🟠 theUserDataRecord.dataID --> \(theUserDataRecord.dataID)")
    }

    func fetchUserData(from tempplatePtr: UnsafeMutablePointer<Deftemplate>) -> UserData? {
        guard let userDataPtr = CLIPSCore.FetchUserData(ptr, theUserDataRecord.dataID, &tempplatePtr.pointee.header.usrData)
        else { return nil }

        let swiftUserDataPtr = UnsafeMutableRawPointer(userDataPtr).assumingMemoryBound(to: SwiftUserData.self)
        guard let instancePtr = swiftUserDataPtr.pointee.instance else { return nil }
        return Unmanaged<UserData>.fromOpaque(instancePtr).takeUnretainedValue()
    }

    func assertCallback(factPtr: UnsafeMutablePointer<Fact>) {
        if let name = factPtr.pointee.whichDeftemplate.pointee.header.name.pointee.contents {
            let nameString = String(cString: name)
            print("clipsFactAssertCallback -- \(nameString)")
        }
    }
}
