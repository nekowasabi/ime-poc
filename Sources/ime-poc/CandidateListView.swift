import Cocoa

protocol CandidateListViewDelegate: AnyObject {
    func candidateListView(_ view: CandidateListView, didSelectCandidate candidate: String)
}

class CandidateListView: NSView {
    weak var delegate: CandidateListViewDelegate?
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var candidates: [String] = []
    private let rowHeight: CGFloat = 24
    private let padding: CGFloat = 10
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8
        
        scrollView = NSScrollView(frame: bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = rowHeight
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CandidateColumn"))
        column.width = bounds.width
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        addSubview(scrollView)
        
        setupKeyboardHandling()
    }
    
    private func setupKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard self?.window?.isKeyWindow == true else { return event }
            
            switch event.keyCode {
            case 125: // Down arrow
                self?.selectNextCandidate()
                return nil
            case 126: // Up arrow
                self?.selectPreviousCandidate()
                return nil
            case 36, 76: // Enter or Return
                self?.confirmSelection()
                return nil
            case 53: // Escape
                self?.delegate?.candidateListView(self!, didSelectCandidate: "")
                return nil
            default:
                return event
            }
        }
    }
    
    func updateCandidates(_ newCandidates: [String]) {
        candidates = newCandidates
        tableView.reloadData()
        
        if !candidates.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    func calculateWindowSize() -> NSSize {
        let height = min(CGFloat(candidates.count) * (rowHeight + 2) + padding * 2, 200)
        return NSSize(width: 250, height: height)
    }
    
    private func selectNextCandidate() {
        let currentRow = tableView.selectedRow
        if currentRow < candidates.count - 1 {
            tableView.selectRowIndexes(IndexSet(integer: currentRow + 1), byExtendingSelection: false)
            tableView.scrollRowToVisible(currentRow + 1)
        }
    }
    
    private func selectPreviousCandidate() {
        let currentRow = tableView.selectedRow
        if currentRow > 0 {
            tableView.selectRowIndexes(IndexSet(integer: currentRow - 1), byExtendingSelection: false)
            tableView.scrollRowToVisible(currentRow - 1)
        }
    }
    
    private func confirmSelection() {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < candidates.count {
            delegate?.candidateListView(self, didSelectCandidate: candidates[selectedRow])
        }
    }
}

extension CandidateListView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return candidates.count
    }
}

extension CandidateListView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("CandidateCell")
        
        let cell: NSTextField
        if let recycledCell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTextField {
            cell = recycledCell
        } else {
            cell = NSTextField()
            cell.identifier = cellIdentifier
            cell.isBordered = false
            cell.isEditable = false
            cell.backgroundColor = .clear
        }
        
        cell.stringValue = candidates[row]
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // Handle selection change if needed
    }
}