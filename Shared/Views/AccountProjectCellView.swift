//
//  AccountProjectCellView.swift
//  BuildablePortal
//
//  Created by Grey Patterson on 9/7/20.
//

import SwiftUI

struct AccountProjectCellView: View {
    let accountProject: AccountProject
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle().fill(Color(accountProject.isCurrent ? "green" : "")).frame(width: 5, height: 5, alignment: .leading)
                Text(accountProject.name ?? "Unknown")
                Spacer()
            }
            if let dStart = accountProject.dateStart, let dEnd = accountProject.dateEnd {
                Text("\(dStart, style: .date)-\(dEnd, style: .date)").font(.footnote)
            } else if let dStart = accountProject.dateStart {
                Text("\(dStart, style: .date)-(no end date)").font(.footnote)
            }
        }
    }
}

struct AccountProjectCellView_Previews: PreviewProvider {
    static var previews: some View {
        AccountProjectCellView(accountProject: AccountProject())
    }
}
