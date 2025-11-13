require 'rails_helper'

RSpec.describe "Relationships", type: :request do
  let(:user) { create(:user) }
  let(:relative) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /relationships" do
    it "returns http success" do
      get relationships_path
      expect(response).to have_http_status(:success)
    end

    it "displays relationships" do
      relationship = create(:relationship, user: user, relative: relative)
      get relationships_path
      expect(response.body).to include(relative.display_name)
    end
  end

  describe "GET /relationships/new" do
    it "returns http success" do
      get new_relationship_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /relationships" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          relative_id: relative.id,
          relationship_type: 'parent',
          start_date: Date.today
        }
      end

      it "creates a new relationship" do
        expect {
          post relationships_path, params: { relationship: valid_attributes }
        }.to change(Relationship, :count).by(2)
      end

      it "redirects to relationships index" do
        post relationships_path, params: { relationship: valid_attributes }
        expect(response).to redirect_to(relationships_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          relative_id: user.id,
          relationship_type: 'parent'
        }
      end

      it "does not create a new relationship" do
        expect {
          post relationships_path, params: { relationship: invalid_attributes }
        }.not_to change(Relationship, :count)
      end

      it "renders the new template" do
        post relationships_path, params: { relationship: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /relationships/:id/edit" do
    let(:relationship) { create(:relationship, user: user, relative: relative) }

    it "returns http success" do
      get edit_relationship_path(relationship)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /relationships/:id" do
    let(:relationship) { create(:relationship, user: user, relative: relative) }

    context "with valid parameters" do
      let(:new_attributes) do
        {
          notes: "Updated notes"
        }
      end

      it "updates the relationship" do
        patch relationship_path(relationship), params: { relationship: new_attributes }
        relationship.reload
        expect(relationship.notes).to eq("Updated notes")
      end

      it "redirects to relationships index" do
        patch relationship_path(relationship), params: { relationship: new_attributes }
        expect(response).to redirect_to(relationships_path)
      end
    end
  end

  describe "DELETE /relationships/:id" do
    let!(:relationship) { create(:relationship, user: user, relative: relative) }

    it "destroys the relationship" do
      expect {
        delete relationship_path(relationship)
      }.to change(Relationship, :count).by(-2)
    end

    it "redirects to relationships index" do
      delete relationship_path(relationship)
      expect(response).to redirect_to(relationships_path)
    end
  end

  describe "authorization" do
    let(:other_user) { create(:user) }
    let(:other_relative) { create(:user) }
    let(:other_relationship) { create(:relationship, user: other_user, relative: other_relative) }

    it "prevents editing other users' relationships" do
      get edit_relationship_path(other_relationship)
      expect(response).to redirect_to(relationships_path)
    end

    it "prevents updating other users' relationships" do
      patch relationship_path(other_relationship), params: { relationship: { notes: "Hacked" } }
      expect(response).to redirect_to(relationships_path)
    end

    it "prevents deleting other users' relationships" do
      delete relationship_path(other_relationship)
      expect(response).to redirect_to(relationships_path)
    end
  end
end
