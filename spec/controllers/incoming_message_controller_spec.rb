require 'spec_helper'

describe IncomingMessagesController do
  
  describe 'GET #show' do
    
    before do 
      @campaign_user = mock_model(User)
      @mock_campaign = mock_model(Campaign, :initiator => @campaign_user, 
                                            :visible? => true, 
                                            :editable? => true)
      @mock_incoming_message = mock_model(IncomingMessage, :campaign => @mock_campaign)
      IncomingMessage.stub!(:find).and_return(@mock_incoming_message)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @default_params = { :id => 55, :campaign_id => @mock_campaign.id }
    end
    
    def make_request(params=@default_params)
      get :show, params
    end
    
    it_should_behave_like "an action requiring a visible campaign"
    
    describe 'if the current user is the campaign initiator' do 
      
      before do 
        controller.stub!(:current_user).and_return(@campaign_user)
      end
    
      it 'should create a campaign update' do 
        CampaignUpdate.should_receive(:new)
        make_request
      end
    
    end
  
    describe 'if the current user is not the campaign initiator' do
    
      it 'should not create a campaign update' do 
        CampaignUpdate.should_not_receive(:new)
        make_request
      end
      
    end
    
  end

end