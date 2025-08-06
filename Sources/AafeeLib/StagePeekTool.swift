//
//  DiagnosticTools.swift
//
//
//  Created by Peter Liddle on 5/9/25.
//

import Foundation

@propertyWrapper
class StateValue<Value> {
    private class Box {
        var value: Value
        init(value: Value) {
            self.value = value
        }
    }
    
    private var box: Box

    var wrappedValue: Value {
        get { box.value }
        set { box.value = newValue }
    }

    init(wrappedValue value: Value) {
        self.box = Box(value: value)
    }
}



@propertyWrapper
public class CustomBinding<Value> {
   private var getter: () -> Value
   private var setter: (Value) -> Void

    public var wrappedValue: Value {
       get { getter() }
       set { setter(newValue) }
   }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
       self.getter = get
       self.setter = set
   }
}

public struct StagePeekTool: FlowStage {
    
    @CustomBinding public var stageInput: String
    
    public init(stageInput: CustomBinding<String>) {
        self._stageInput = stageInput
    }
    
    public func execute(_ input: InOutType?) async throws -> InOutType {
        stageInput = (try? input?.text) ?? "NO INPUT"
        logger.debug("\(stageInput)")
        return input ?? .none
    }
}
