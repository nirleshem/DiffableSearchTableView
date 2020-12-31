//
//  MainTableViewController.swift
//  DiffableSearchTableView
//
//  Created by Nir Leshem on 30/12/2020.
//

import UIKit
import Combine
import Moya

class MainTableViewController: UITableViewController {

    //MARK: Properties
    lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.delegate = self
        return search
    }()
        
    enum Section {
        case main
    }
    
    //MARK: Data Source
    lazy var dataSource = UITableViewDiffableDataSource<Section, User>(tableView: tableView, cellProvider: { (tableView, indexPath, model) -> UITableViewCell? in
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.users[indexPath.row].name
        return cell
    })
    
    var outputString: Set<AnyCancellable> = []
    var users = [User]()
    
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Diffable"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = dataSource
        tableView.delegate = self
        setupListeners()
        getUsers()
    }
    
    //MARK: Setup Listeners
    func setupListeners() {
        NotificationCenter.default
            .publisher(for: UISearchTextField.textDidChangeNotification, object: searchController.searchBar.searchTextField)
            .map {
                ($0.object as! UISearchTextField).text
            }
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] string in
                self?.filterArray(with: string)
            }).store(in: &outputString)
    }

    //MARK: Update Snapshot
    func updateSnapshot(users: [User]? = nil) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
        snapshot.appendSections([.main])
        guard let users = users == nil ? self.users : users else { return }
        snapshot.appendItems(users)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: FIlter Array
    func filterArray(with string: String?) {
        guard let string = string else { return }
        if string.isEmpty {
            updateSnapshot()
        } else {
            let sortedList = users.filter({ $0.name.lowercased().contains(string.lowercased()) })
            var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
            snapshot.appendSections([.main])
            snapshot.appendItems(sortedList)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    //MARK: Get Users
    func getUsers() {
        let service = MoyaProvider<NetworkingService.UsersProvider>()
        service.request(.getUsers) { [weak self] result in
            switch result {
            case .success(let response):
                guard let usersList = try? JSONDecoder().decode([User].self, from: response.data) else { return }
                self?.users = usersList
                self?.updateSnapshot(users: self?.users)
            case .failure(let error):
                print("zzz Failure: \(error)")
            }
        }
    }
}

//MARK: TableView Delegate
extension MainTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        print("\(item.name)")
    }
}

//MARK: UISearchBar Cancel Action
extension MainTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateSnapshot()
    }
}
