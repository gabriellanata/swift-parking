import Foundation
import Vapor
import AppKit

struct Ticket: Content, Equatable {
    let citationNumber: String
    let issueDate: String
    let violationCode: String
    let violationDescription: String
    let amountDue: String
    let isUnpaid: Bool

    init(
        citationNumber: String,
        issueDate: String,
        violationCode: String,
        violationDescription: String,
        amountDue: String
    ) {
        self.citationNumber = citationNumber
        self.issueDate = issueDate
        self.violationCode = violationCode
        self.violationDescription = violationDescription
        self.amountDue = amountDue
        self.isUnpaid = amountDue != "$0.00"
    }
}

actor TicketApi {
    public static let shared = TicketApi()

    private var sharedHeaders: HTTPHeaders = [
        "Authority":"wmq.etimspayments.com",
        "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Language":"en-US,en;q=0.9",
        "Cache-Control":"max-age=0",
        "Content-Type":"application/x-www-form-urlencoded",
        "Dnt":"1",
        "Origin":"https://wmq.etimspayments.com",
        "Referer":"https://wmq.etimspayments.com/pbw/include/sanfrancisco/input.jsp",
        "Sec-Ch-Ua":"\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\"",
        "Sec-Ch-Ua-Mobile":"?0",
        "Sec-Ch-Ua-Platform":"\"Android\"",
        "Sec-Fetch-Dest":"document",
        "Sec-Fetch-Mode":"navigate",
        "Sec-Fetch-Site":"same-origin",
        "Sec-Fetch-User":"?1",
        "Upgrade-Insecure-Requests":"1",
        "User-Agent":"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    ]

    func checkForTickets(licensePlate: String) async throws -> [Ticket] {
        let rawResponse = try await Api.shared.send(
            method: .POST,
            url: "https://wmq.etimspayments.com/pbw/inputAction.doh",
            headers: self.sharedHeaders,
            body: [
                "clientcode":"19",
                "requestType":"submit",
                "requestCount":"1",
                "clientAccount":"5",
//                "ticketNumber":"",
                "plateNumber":licensePlate,
                "statePlate":"CA",
                "submit":"++Search+for+citations++",
            ]
        )

        guard let html = rawResponse.body?.asString() else {
            throw Abort(.internalServerError)
        }

        var citations: [Ticket] = []

        let lines = html.components(separatedBy: .newlines)

        var citationNumber: String?
        var issueDate: String?
        var violationCode: String?
        var violationDescription: String?
        var amountDue: String?

        for line in lines {
            if line.contains("javascript:submitTicketDetail(") {
                if citationNumber == nil {
                    print()
                    if let text = line.extractText(start: "submitTicketDetail('", end: "')") {
                        citationNumber = text
                    } else {
                        throw Abort(.internalServerError, reason: "Unable to extract citation number")
                    }
                } else {
                    print("citationNumber", citationNumber ?? "nil")
                    print("issueDate", issueDate ?? "nil")
                    print("violationCode", violationCode ?? "nil")
                    print("violationDescription", violationDescription ?? "nil")
                    print("amountDue", amountDue ?? "nil")
                    throw Abort(.internalServerError, reason: "Missed data after citation number")
                }
            }

            if line.contains("\t<td class=\"bodySmall\">") {
                guard let text = line.extractText(start: "<td class=\"bodySmall\">", end: "</td>") else {
                    throw Abort(.internalServerError, reason: "Unable to extract middle data")
                }

                if issueDate == nil {
                    issueDate = text
                } else if violationCode == nil {
                    violationCode = text
                } else if violationDescription == nil {
                    violationDescription = text
                } else {
                    throw Abort(.internalServerError, reason: "Found extra data in middle")
                }
            }

            if line.contains("\t<td class=\"bodySmall\" style=\"text-align:right\">") {
                guard let text = line.extractText(start: "style=\"text-align:right\">", end: "</td>") else {
                    throw Abort(.internalServerError, reason: "Unable to extract amount info")
                }

                amountDue = text

                if let citationNumber,
                   let issueDate,
                   let violationCode,
                   let violationDescription,
                   let amountDue
                {
                    citations.append(Ticket(
                        citationNumber: citationNumber,
                        issueDate: issueDate,
                        violationCode: violationCode,
                        violationDescription: violationDescription,
                        amountDue: amountDue
                    ))
                } else {
                    throw Abort(.internalServerError, reason: "Finished line but did not get all data")
                }

                citationNumber = nil
                issueDate = nil
                violationCode = nil
                violationDescription = nil
                amountDue = nil
            }
        }

        return citations
    }

}

