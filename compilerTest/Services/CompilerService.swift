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
    
    func encodeCode(code : String) -> String {
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
        var codeUsed = code.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        for key in dictReplace.keys {
            codeUsed = codeUsed.replacingOccurrences(of: key, with: dictReplace[key]!)
        }
        
        return codeUsed
    }
    
    func compileCode(code : String) {
        let urlUsed = "\(createUrl)\(encodeCode(code: code))"
        
        guard let (request, session) = getRequestAndSession(urlUsed: urlUsed) else {
            return
        }
        
        request.httpMethod = "POST"
        
        let task = session.dataTask(with: request as URLRequest) { [self] data, response, error in
            if error != nil {
                return
            }
            if let result = data {
                if let decodableObject = (self.parseJSONToDecodable(decodableClass: CompilerId.self, data: result) as? CompilerId) {
                    
                    let compilerId = CompilerId(id: decodableObject.id)
                    
                    DispatchQueue.main.async {
                        checkStatus(id: compilerId.id)
                        
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
                            print("timer is running")
                            
                            if self.status == "completed" {
                                print("compiling done")

                                getResult(id: compilerId.id)

                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in

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
        task.resume()
    }
    
    func checkStatus(id : String) {
        let urlUsed = "\(statusUrl)\(id)"
        
        guard let (request, session) = getRequestAndSession(urlUsed: urlUsed) else {
            return
        }
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest) { [self] data, response, error in
            if let result = data, let decodableObject = (self.parseJSONToDecodable(decodableClass: CompilerStatus.self, data: result) as? CompilerStatus) {
                
                self.status = decodableObject.status
                
            }
        }
        task.resume()
    }
    
    func getResult(id : String) {
        let urlUsed = "\(resultUrl)\(id)"
        
        guard let (request, session) = getRequestAndSession(urlUsed: urlUsed) else {
            return
        }
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if let result = data, let decodableObject = (self.parseJSONToDecodable(decodableClass: CompilerResult.self, data: result) as? CompilerResult) {
                
                self.result = decodableObject.build_result
                
                self.output = (self.result == "success" ? decodableObject.stdout : decodableObject.build_stderr)!
            }
        }
        
        task.resume()
    }
    
    func getRequestAndSession(urlUsed : String) -> (NSMutableURLRequest, URLSession)? {
        guard let url = URL(string: urlUsed) else {
            return nil
        }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        
        return (request, session)
    }
    
    
    func parseJSONToDecodable<T: Decodable>(decodableClass: T.Type, data : Data) -> Decodable? {
        let decoder = JSONDecoder()
        
        do {
            let decodableObject = try decoder.decode(decodableClass.self, from: data)
            return decodableObject
            
        } catch {
            return nil
        }
    }
}
