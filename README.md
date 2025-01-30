# PixelPort

Welcome to **PixelPort**, a decentralized platform for creating, trading, and managing NFTs. This smart contract is designed to facilitate seamless NFT minting, transfers, sales, and purchases with built-in marketplace features.

## Features

- **Mint NFTs**: Users can mint new NFTs with custom metadata.
- **Transfer NFTs**: Safely transfer NFTs between users.
- **List NFTs for Sale**: Put your NFTs up for sale with specified prices.
- **Buy NFTs**: Purchase NFTs listed on the marketplace with secure transactions.
- **Marketplace Fee**: A small fee is deducted from each transaction, supporting the platform.
- **Pause/Unpause Marketplace**: Admin can pause or resume the marketplace functionality.

## Core Functions

- **Minting**: Create a new NFT with a unique ID and metadata URI.
- **Transfer**: Transfer NFTs to other users, verifying ownership.
- **Marketplace Listings**: List your NFTs for sale with a price and expiration time.
- **Buy Token**: Secure purchasing of listed NFTs, with the ability to handle marketplace fees.
- **Admin Controls**: Adjust marketplace fees and pause/unpause the platform.

## How to Use

1. **Minting an NFT**:
   - Call the `mint(metadata-url)` function, passing the URI of the metadata (e.g., an image or a JSON file).
   
2. **Transfer an NFT**:
   - Call `transfer(token-id, sender, recipient)` to transfer ownership of an NFT from one user to another.

3. **Listing an NFT for Sale**:
   - Call `list-token(token-id, price, expiry)` to list your NFT for sale at a specified price, with an expiration time.

4. **Buying an NFT**:
   - Call `buy-token(token-id)` to purchase a listed NFT. The platform will handle the fee and transfer the token accordingly.

5. **Admin Actions**:
   - The contract owner can modify the marketplace fee with `set-marketplace-fee(new-fee)` and pause/unpause the marketplace using `toggle-marketplace-pause`.

## Deployment

To deploy **PixelPort**, use the following steps:

1. Install [Clarinet](https://github.com/hiRoFaX/clarinet) and [Stacking](https://docs.blockstack.org) if not already set up.
2. Deploy the contract using the Clarinet CLI with `clarinet deploy`.
3. Interact with the contract through the Clarinet console or integrate with your front-end application.

## Future Improvements

- Implement advanced bidding mechanisms.
- Add more robust user feedback systems (reviews, ratings).
- Integrate with popular NFT standards for broader interoperability.

## License

PixelPort is licensed under the [MIT License](LICENSE).