//
//  ScannerVieww.swift
//  Barcode-Scanner
//
//  Created by Nathan Patterson on 7/26/23.
//

import SwiftUI

struct ScannerVieww: UIViewControllerRepresentable {
    
    @Binding var scannedCode: String
    
    func makeUIViewController(context: Context) -> ScannerVC {
        ScannerVC(scannerDelegate: context.coordinator)
    }
    
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannerView: self)
    }
    
    final class Coordinator: NSObject, ScannerVCDelegate {
        
        private let scannerView: ScannerVieww
        
        init(scannerView: ScannerVieww) {
            self.scannerView = scannerView
        }
        
        func didFind(barcode: String) {
            scannerView.scannedCode = barcode
            
        }                                           // This is UIKit passing the barcode to the coordinator
        
        func didSurface(error: CameraError) {
            print(error.rawValue)
        }
        
        
    }

}

struct ScannerVieww_Previews: PreviewProvider {
    static var previews: some View {
        ScannerVieww(scannedCode: .constant("123456"))
    }
}
