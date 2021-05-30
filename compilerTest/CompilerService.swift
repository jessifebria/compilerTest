//
//  CompilerService.swift
//  compilerTest
//
//  Created by Jessi Febria on 30/05/21.
//

import Foundation

protocol CompilerServiceDelegate {
    func updateUI(result: String, output: String)
}


class CompilerService {
    
    let createUrl = "https://paiza-io.p.rapidapi.com/runners/create?language=swift&api_key=guest&source_code="
    let statusUrl = "https://paiza-io.p.rapidapi.com/runners/get_status?&api_key=guest&id="
    let resultUrl = "https://paiza-io.p.rapidapi.com/runners/get_details?&api_key=guest&id="
    
    var status = "failed"
    var output = ""
    var result = ""
    
    var delegate: CompilerServiceDelegate?
    
    let headers = [
        "x-rapidapi-key": "2780abb760mshaa5a03c99c2b01ap1675a0jsn506a2d0bedff",
        "x-rapidapi-host": "paiza-io.p.rapidapi.com"
    ]
    
    func compileCode(code : String) {
        // create URL
        
        var codeUsed = code.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        let dictReplace = [
            "$" : "%24",
            "&" : "%26",
            "+" : "%2B",
            "," : "%2C",
            ":" : "%3A",
            ";" : "%3B",
            "=" : "%3D",
            "?" : "%3F",
            "@" : "%40",
            "\n" : " "
        ]
        
        for key in dictReplace.keys {
            codeUsed = codeUsed.replacingOccurrences(of: key, with: dictReplace[key]!)
        }
        
        let urlUsed = "\(createUrl)\(codeUsed)"
        
        print(urlUsed)
        
        guard let URLUsed = URL(string: urlUsed) else {
            return
        }
        
        // create request
        
        let request = NSMutableURLRequest(url: URLUsed, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        
        // create URLSession
        let session = URLSession(configuration: .default)
        
        // give the session a task
        let task = session.dataTask(with: request as URLRequest) { [self] data, response, error in
            if error != nil {
                return
            }
            if let result = data {
                if let compilerId = self.parseJSONToCompilerId(data: result) {
                    DispatchQueue.main.async {
                        checkStatus(id: compilerId.id)
                        
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
                            print(status)
                            print("timer is running")
                            
                            if self.status == "completed" {
                                print("compiling done")
                                
                                getResult(id: compilerId.id)
                                
                                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                                    print("\(result) \(output)")
                                    
                                    self.delegate?.updateUI(result: self.result, output: self.output)
                                    
                                }
                                
                                
                                timer.invalidate()
                            } else {
                                checkStatus(id: compilerId.id)
                            }
                        }
                    }
                    
                    
                }
            }
        }
        
        // start the task
        task.resume()
        
    }
    
    func parseJSONToCompilerId(data : Data) -> CompilerId?{
        
        let decoder = JSONDecoder()
        
        do {
            let decodableObject = try decoder.decode(CompilerId.self, from: data)
            
            let compilerModel = CompilerId(id: decodableObject.id)
            
            return compilerModel
        } catch {
            return nil
        }
        
    }
    
    func checkStatus(id : String) {
        
        let urlUsed = "\(statusUrl)\(id)"
        
        guard let url = URL(string: urlUsed) else {
            return
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            let decoder = JSONDecoder()
            if let data = data {
                print(data)
                do {
                    let decodableObject = try decoder.decode(CompilerStatus.self, from: data)
                    let compilerModel = CompilerStatus(status: decodableObject.status)
                    
                    self.status = compilerModel.status
                    print("\(self.status) \(compilerModel.status)")
                } catch {
                    print("error checking status of compiler")
                }
            }
        }
        
        task.resume()
        
    }
    
    func getResult(id : String) {
        
        let urlUsed = "\(resultUrl)\(id)"
        
        print(urlUsed)
        
        guard let url = URL(string: urlUsed) else {
            return
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            let decoder = JSONDecoder()
            if let data = data {
                print(data)
                do {
                    
                    let decodableObject = try decoder.decode(CompilerResult.self, from: data)
                    
                    let compilerModel = CompilerResult(build_result: decodableObject.build_result, stdout: decodableObject.stdout, build_stderr: decodableObject.build_stderr)
                    
                    self.result = compilerModel.build_result
                    
                    self.output = (self.result == "success" ? compilerModel.stdout : compilerModel.build_stderr)!
                    
                } catch {
                    print("error checking status of compiler")
                }
            }
        }
        
        task.resume()
        
    }
    
    
}
