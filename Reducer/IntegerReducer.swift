//
//  File.swift
//  
//
//  Created by 戴藏龙 on 2024/1/4.
//

import Foundation

enum IntegerReducer: Codable {
    case multiColumnReducer(MultiColumnReducer)
    case singleColumnReducer(SingleColumnReducer)

    enum MultiColumnReducer: Codable {
        case add(MultiColumnReducerParameter)
        case subtract(MultiColumnReducerParameter)
        case multiply(MultiColumnReducerParameter)
        case dividedBy(MultiColumnReducerParameter)
        case equalTo(MultiColumnReducerParameter)
        case moreThan(MultiColumnReducerParameter)
        case lessThan(MultiColumnReducerParameter)
        case moreThanOrEqualTo(MultiColumnReducerParameter)
        case lessThanOrEqualTo(MultiColumnReducerParameter)
    }
    enum SingleColumnReducer: Codable {
        case add(SingleColumnWithParameterReducerParameter<Int>)
        case subtract(SingleColumnWithParameterReducerParameter<Int>)
        case multiply(SingleColumnWithParameterReducerParameter<Int>)
        case dividedBy(SingleColumnWithParameterReducerParameter<Int>)
        case equalTo(SingleColumnWithParameterReducerParameter<Int>)
        case moreThan(SingleColumnWithParameterReducerParameter<Int>)
        case lessThan(SingleColumnWithParameterReducerParameter<Int>)
        case moreThanOrEqualTo(SingleColumnWithParameterReducerParameter<Int>)
        case lessThanOrEqualTo(SingleColumnWithParameterReducerParameter<Int>)
        case castDouble(SingleColumnReducerParameter)
        case castString(SingleColumnReducerParameter)
        case percentage(SingleColumnReducerParameter)
        case fillNil(SingleColumnWithParameterReducerParameter<Int>)
    }
}
