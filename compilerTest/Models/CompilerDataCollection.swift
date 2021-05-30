//
//  CompilerData.swift
//  compilerTest
//
//  Created by Jessi Febria on 30/05/21.
//

import Foundation

struct CompilerId : Decodable {
    let id : String
}

struct CompilerStatus : Decodable {
    let status : String
}

struct CompilerResult : Decodable {
    let build_result : String
    let stdout : String?
    let build_stderr : String?
    
}
