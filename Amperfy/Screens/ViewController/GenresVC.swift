import UIKit
import CoreData

class GenresVC: SingleFetchedResultsTableViewController<GenreMO> {

    private var fetchedResultsController: GenreFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.userStatistics.visited(.genres)
        
        fetchedResultsController = GenreFetchedResultsController(managedObjectContext: appDelegate.persistentStorage.context, isGroupedInAlphabeticSections: true)
        singleFetchedResultsController = fetchedResultsController
        
        configureSearchController(placeholder: "Search in \"Genres\"", scopeButtonTitles: ["All", "Cached"])
        tableView.register(nibName: GenericTableCell.typeName)
        tableView.rowHeight = GenericTableCell.rowHeightWithoutImage
        self.refreshControl?.addTarget(self, action: #selector(Self.handleRefresh), for: UIControl.Event.valueChanged)
        
        containableAtIndexPathCallback = { (indexPath) in
            return self.fetchedResultsController.getWrappedEntity(at: indexPath)
        }
        swipeCallback = { (indexPath, completionHandler) in
            let genre = self.fetchedResultsController.getWrappedEntity(at: indexPath)
            genre.fetchAsync(storage: self.appDelegate.persistentStorage, backendApi: self.appDelegate.backendApi) {
                completionHandler(SwipeActionContext(containable: genre))
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: GenericTableCell = dequeueCell(for: tableView, at: indexPath)
        let genre = fetchedResultsController.getWrappedEntity(at: indexPath)
        cell.display(container: genre, rootView: self)
        cell.entityImage.isHidden = true
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let genre = fetchedResultsController.getWrappedEntity(at: indexPath)
        performSegue(withIdentifier: Segues.toGenreDetail.rawValue, sender: genre)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.toGenreDetail.rawValue {
            let vc = segue.destination as! GenreDetailVC
            let genre = sender as? Genre
            vc.genre = genre
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        fetchedResultsController.search(searchText: searchText, onlyCached: searchController.searchBar.selectedScopeButtonIndex == 1)
        tableView.reloadData()
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        appDelegate.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
            if self.appDelegate.persistentStorage.settings.isOnlineMode {
                let syncLibrary = LibraryStorage(context: context)
                let syncer = self.appDelegate.backendApi.createLibrarySyncer()
                syncer.syncLatestLibraryElements(library: syncLibrary)
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            }

        }
    }

}

