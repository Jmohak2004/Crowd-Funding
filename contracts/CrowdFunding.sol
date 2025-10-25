// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Crowdfunding {
    struct Campaign {
        address payable creator;   // Owner of the campaign
        string title;              // Title of the campaign
        string description;        // Description of the campaign
        uint goal;                 // Fundraising goal in wei
        uint deadline;             // Campaign end time (timestamp)
        uint amountCollected;      // Total donations collected
        bool withdrawn;            // Whether funds were withdrawn
    }

    struct Donation {
        address donor;
        uint amount;
    }

    mapping(uint => Donation[]) public donations; // campaignId -> donations
    mapping(uint => Campaign) public campaigns;   // campaignId -> Campaign

    uint public campaignCount; // total number of campaigns

    // Events for tracking actions
    event CampaignCreated(uint indexed campaignId, address indexed creator, string title, uint goal, uint deadline);
    event DonationReceived(uint indexed campaignId, address indexed donor, uint amount);
    event FundsWithdrawn(uint indexed campaignId, address indexed creator, uint amount);

    // Create a new campaign
    function createCampaign(string memory _title, string memory _description, uint _goal, uint _durationInDays) external {
        require(_goal > 0, "Goal must be greater than zero");
        require(_durationInDays > 0, "Duration must be greater than zero");

        campaignCount++;
        uint _deadline = block.timestamp + (_durationInDays * 1 days);

        campaigns[campaignCount] = Campaign({
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goal: _goal,
            deadline: _deadline,
            amountCollected: 0,
            withdrawn: false
        });

        emit CampaignCreated(campaignCount, msg.sender, _title, _goal, _deadline);
    }

    // Donate to a specific campaign
    function donateToCampaign(uint _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be greater than zero");

        campaign.amountCollected += msg.value;
        donations[_campaignId].push(Donation(msg.sender, msg.value));

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    // View all campaigns
    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);
        for (uint i = 1; i <= campaignCount; i++) {
            allCampaigns[i - 1] = campaigns[i];
        }
        return allCampaigns;
    }

    // View donations for a specific campaign
    function getDonations(uint _campaignId) external view returns (Donation[] memory) {
        return donations[_campaignId];
    }

    // Withdraw funds if goal met or deadline passed
    function withdrawFunds(uint _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only creator can withdraw");
        require(!campaign.withdrawn, "Funds already withdrawn");
        require(block.timestamp >= campaign.deadline || campaign.amountCollected >= campaign.goal, "Goal not reached or campaign still active");

        campaign.withdrawn = true;
        uint amount = campaign.amountCollected;
        campaign.amountCollected = 0;
        campaign.creator.transfer(amount);

        emit FundsWithdrawn(_campaignId, msg.sender, amount);
    }
}
