// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Market {
    struct Offer {
        address seller;
        uint256 amount; // kWh
        uint256 pricePerUnit; // unit price
        bool isAvailable;
    }

    IERC20 public token; // ERC20 coins
    uint256 public offerCounter;
    mapping(uint256 => Offer) public offers;

    event OfferCreated(uint256 indexed offerId, address indexed seller, uint256 amount, uint256 pricePerUnit);
    event OfferCancelled(uint256 indexed offerId, address indexed seller);
    event Purchased(uint256 indexed offerId, address indexed buyer, uint256 amount, uint256 totalPrice);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function createOffer(uint256 _amount, uint256 _pricePerUnit) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(_pricePerUnit > 0, "Price per unit must be greater than zero");

        offers[offerCounter] = Offer({
            seller: msg.sender,
            amount: _amount,
            pricePerUnit: _pricePerUnit,
            isAvailable: true
        });

        emit OfferCreated(offerCounter, msg.sender, _amount, _pricePerUnit);
        offerCounter++;
    }

    function purchase(uint256 offerId, uint256 purchaseAmount) external {
        Offer storage offer = offers[offerId];
        require(offer.isAvailable, "Offer is not available");
        require(purchaseAmount > 0 && purchaseAmount <= offer.amount, "Invalid purchase amount");

        uint256 totalPrice = purchaseAmount * offer.pricePerUnit;

        require(token.transferFrom(msg.sender, offer.seller, totalPrice), "Payment failed");

        offer.amount -= purchaseAmount;
        if (offer.amount == 0) {
            offer.isAvailable = false;
        }

        emit Purchased(offerId, msg.sender, purchaseAmount, totalPrice);
    }

    function cancelOffer(uint256 offerId) external {
        Offer storage offer = offers[offerId];
        require(msg.sender == offer.seller, "Only seller can cancel");
        require(offer.isAvailable, "Offer is already inactive");

        offer.isAvailable = false;
        emit OfferCancelled(offerId, msg.sender);
    }
}
