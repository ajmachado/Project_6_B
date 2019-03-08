pragma solidity >=0.4.24;

// Import the Access Control and Core contracts
import "../vegetableaccesscontrol/FarmerRole.sol";
import "../vegetableaccesscontrol/DistributorRole.sol";
import "../vegetableaccesscontrol/RetailerRole.sol";
import "../vegetableaccesscontrol/ConsumerRole.sol";
import "../vegetablecore/Ownable.sol";


// Define a contract 'Supplychain'
contract SupplyChain is FarmerRole, DistributorRole, ConsumerRole, RetailerRole, Ownable{

  // Define 'owner'
  address sc_owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a variable called 'productId' as an unique identifier
  uint  productId;

  // Define a public mapping 'items' that maps the productId to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the productId to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Planted, //0
    Grown, //1
    Harvested,  // 2
    Processed,  // 3
    Packaged,     // 4
    ForSale,    // 5
    Sold,  //6
    Shipped,    // 7
    Received,   // 8
    Purchased   // 9
  }

  State constant defaultState = State.Planted;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    string  productImage; //IPFS hash for product image
    address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint  productID;  // Product ID potentially a combination of upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address distributorID;  // Metamask-Ethereum address of the Distributor
    address retailerID; // Metamask-Ethereum address of the Retailer
    address consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Planted(uint productId);
  event Grown(uint productId);
  event Harvested(uint productId);
  event Processed(uint productId);
  event Packaged(uint productId);
  event ForSale(uint productId);
  event Sold(uint productId);
  event Shipped(uint productId);
  event Received(uint productId);
  event Purchased(uint productId);
  event ImageUploaded(uint productId);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == sc_owner);
    _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _productId) {
    _;
    uint _price = items[_productId].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_productId].distributorID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Planted
  modifier planted(uint _productId) {
    require(items[_productId].itemState == State.Planted);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Grown
  modifier grown(uint _productId) {
    require(items[_productId].itemState == State.Grown);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _productId) {
    require(items[_productId].itemState == State.Harvested);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _productId) {
    require(items[_productId].itemState == State.Processed);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Packaged
  modifier packaged(uint _productId) {
    require(items[_productId].itemState == State.Packaged);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _productId) {
    require(items[_productId].itemState == State.ForSale);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _productId) {
    require(items[_productId].itemState == State.Sold);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _productId) {
    require(items[_productId].itemState == State.Shipped);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _productId) {
    require(items[_productId].itemState == State.Received);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _productId) {
    require(items[_productId].itemState == State.Purchased);
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    sc_owner = msg.sender;
    sku = 1;
    upc = 1;
    productId = 1;
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == sc_owner) {
      selfdestruct(sc_owner);
    }
  }

  // Define a function 'plantItem' that allows a farmer to mark an item 'Planted'
  function plantItem 
    (
      uint _upc, 
      address _originFarmerID, 
      string memory _originFarmName, 
      string memory _originFarmInformation, 
      string memory _originFarmLatitude, 
      string memory _originFarmLongitude, 
      string memory _productNotes
      ) 
      verifyCaller(_originFarmerID)
      onlyFarmer
      public 
  {
    //Add Item
    items[productId] = Item({
      sku: sku, 
      upc: _upc, 
      productImage: "",
      ownerID: msg.sender, 
      originFarmerID: _originFarmerID,
      originFarmName: _originFarmName,
      originFarmInformation: _originFarmInformation,
      originFarmLatitude: _originFarmLatitude,
      originFarmLongitude: _originFarmLongitude,
      productID: productId,
      productNotes: _productNotes,
      productPrice: 0,
      itemState: State.Planted, 
      distributorID: address(0), 
      retailerID: address(0),
      consumerID:address(0)
      });

    // Increment sku and productId
    sku = sku + 1;
    productId = productId + 1;

    // Emit the appropriate event
    emit Planted(productId);
   
  }

  // Define a function 'growItem' that allows a farmer to mark an item 'Grown'
  function growItem(uint _productId) 
    verifyCaller(items[_productId].originFarmerID) 
    planted(_productId) 
    onlyFarmer
    public 
  {
    // Add the new item as part of Grown
    items[_productId].itemState = State.Grown;
    
    // Emit the appropriate event
    emit Grown(_productId);
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(uint _productId) 
    verifyCaller(items[_productId].originFarmerID) 
    grown(_productId) 
    onlyFarmer
    public 
  {
    // Add the new item as part of Harvest
    items[_productId].itemState = State.Harvested;
    
    // Emit the appropriate event
    emit Harvested(_productId);    
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _productId) 
    verifyCaller(items[_productId].originFarmerID) 
    harvested(_productId) 
    onlyFarmer
    public 
  {
    // Update the appropriate fields
    items[_productId].itemState = State.Processed;
    
    // Emit the appropriate event
    emit Processed(_productId);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packageItem(uint _productId) 
    verifyCaller(items[_productId].originFarmerID) 
    processed(_productId) 
    onlyFarmer
    public 
  {
    // Update the appropriate fields
    items[_productId].itemState = State.Packaged;
    
    // Emit the appropriate event
    emit Packaged(_productId);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _productId, uint _price) 
    verifyCaller(items[_productId].originFarmerID) 
    packaged(_productId) 
    onlyFarmer
    public 
  {
    // Update the appropriate fields
    items[_productId].itemState = State.ForSale;
    items[_productId].productPrice = _price;
    
    // Emit the appropriate event
    emit ForSale(_productId);    
  }

  // Define a function 'upload' that allows a farmer to upload product image
  function upload(uint _productId, string memory _image) 
    onlyFarmer
    public 
  {
    // Update the appropriate fields
    items[_productId].productImage = _image;
    
    // Emit the appropriate event
    emit ImageUploaded(productId);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _productId) 
    forSale(_productId) 
    paidEnough(items[_productId].productPrice) 
    checkValue(_productId) 
    onlyDistributor
    public 
    payable 
  {
    // Update the appropriate fields - ownerID, distributorID, itemState
    items[_productId].itemState = State.Sold;
    items[_productId].ownerID = msg.sender;
    items[_productId].distributorID = msg.sender;
    
    // Transfer money to farmer
    uint256 price = items[_productId].productPrice;
    items[_productId].originFarmerID.transfer(price);
    
    // emit the appropriate event
    emit Sold(_productId);
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifiers to check if the item is sold
  function shipItem(uint _productId) 
    sold(_productId) 
    verifyCaller(items[_productId].distributorID)
    onlyDistributor 
    public 
  {
    // Update the appropriate fields
    items[_productId].itemState = State.Shipped;
    
    // Emit the appropriate event
    emit Shipped(_productId);
    
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _productId) 
    shipped(_productId) 
    onlyRetailer
    public 
  {
    // Update the appropriate fields - ownerID, retailerID, itemState
    items[_productId].itemState = State.Received;
    items[_productId].ownerID = msg.sender;
    items[_productId].retailerID = msg.sender;
    
    // Emit the appropriate event
    emit Received(_productId);    
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _productId) 
    received(_productId) 
    onlyConsumer
    public 
  {
    // Update the appropriate fields - ownerID, consumerID, itemState
    items[_productId].itemState = State.Purchased;
    items[_productId].ownerID = msg.sender;
    items[_productId].consumerID = msg.sender;
    
    // Emit the appropriate event
    emit Purchased(_productId);    
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _productId) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  address ownerID,
  address originFarmerID,
  string  memory originFarmName,
  string  memory originFarmInformation,
  string  memory originFarmLatitude,
  string  memory originFarmLongitude
  
  ) 
  {
  // Assign values to the 8 parameters
  itemSKU = items[_productId].sku;
  itemUPC = items[_productId].upc;
  ownerID = items[_productId].ownerID;
  originFarmerID = items[_productId].originFarmerID;
  originFarmName = items[_productId].originFarmName;
  originFarmInformation = items[_productId].originFarmInformation;
  originFarmLatitude = items[_productId].originFarmLatitude;
  originFarmLongitude =items[_productId].originFarmLongitude;
  
    
  return 
  (
  itemSKU,
  itemUPC,
  ownerID,
  originFarmerID,
  originFarmName,
  originFarmInformation,
  originFarmLatitude,
  originFarmLongitude
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _productId) public view returns 
    (
    uint    itemSKU,
    uint    itemUPC,
    uint    productID,
    string memory productImage,
    string  memory productNotes,
    uint    productPrice,
    uint    itemState,
    address distributorID,
    address retailerID,
    address consumerID
    ) 
  {
    // Assign values to the 9 parameters
    itemSKU = items[_productId].sku;
    itemUPC = items[_productId].upc;
    productID = _productId;
    productNotes = items[_productId].productNotes;
    productPrice = items[_productId].productPrice;
    itemState = uint(items[_productId].itemState);
    distributorID = items[_productId].distributorID;
    retailerID = items[_productId].retailerID;
    consumerID = items[_productId].consumerID; 
    productImage = items[_productId].productImage;
    
    return 
    (
    itemSKU,
    itemUPC,
    productID,
    productImage,
    productNotes,
    productPrice,
    itemState,
    distributorID,
    retailerID,
    consumerID
    );
  }
}
