# Family Relationships System Guide

## Overview

This Rails family tree application now includes a comprehensive family relationship system that allows users to create, manage, and visualize complex family connections.

## Database Schema

### Relationship Model

The `relationships` table uses a self-referential join approach:

- `user_id`: The person creating/owning the relationship
- `relative_id`: The related family member
- `relationship_type`: Type of relationship (see types below)
- `start_date`: Optional start date (birth, marriage, etc.)
- `end_date`: Optional end date (death, divorce, etc.)
- `notes`: Additional information about the relationship

### Indexes

The following indexes ensure efficient querying:
- Composite index on `user_id`, `relative_id`, `relationship_type`
- Index on `relative_id`, `user_id` for reverse lookups

## Relationship Types

The system supports the following relationship types:

### Parent-Child Relationships
- `parent` / `child` - Generic parent-child
- `biological_parent` / `biological_child` - Biological relationships
- `adoptive_parent` / `adoptive_child` - Adoptive relationships
- `step_parent` / `step_child` - Step-family relationships

### Spousal Relationships
- `spouse` - Current married partner
- `ex_spouse` - Divorced spouse
- `partner` - Current unmarried partner
- `ex_partner` - Former unmarried partner

### Sibling Relationships
- `sibling` - Full sibling (same parents)
- `half_sibling` - Half sibling (one shared parent)
- `step_sibling` - Step sibling (no shared parents)

## Key Features

### Automatic Reciprocal Relationships

When you create a relationship, the system automatically creates the reciprocal relationship:
- If A is the parent of B, B automatically becomes the child of A
- If A is the spouse of B, B automatically becomes the spouse of A
- If A is the sibling of B, B automatically becomes the sibling of A

### Validations

The system includes comprehensive validations:
- Users cannot be their own relative
- End dates must be after start dates
- Duplicate relationships are prevented
- Relationship types must be valid

### Authorization

Privacy is built-in:
- Only the relationship creator or participants can edit/delete relationships
- All relationship operations require authentication

## Using the System

### Routes

```ruby
GET    /relationships              # List all relationships
GET    /relationships/new          # Form to create new relationship
POST   /relationships              # Create relationship
GET    /relationships/:id/edit     # Edit relationship
PATCH  /relationships/:id          # Update relationship
DELETE /relationships/:id          # Delete relationship
GET    /family_tree                # View your family tree
GET    /family_tree/:id            # View another user's family tree
```

### Creating Relationships

1. Navigate to `/relationships/new`
2. Select the family member from the dropdown
3. Choose the relationship type
4. Optionally add start/end dates and notes
5. Submit the form

The reciprocal relationship will be created automatically.

### Viewing Family Trees

Navigate to `/family_tree` to see your family tree with:
- Grandparents
- Parents
- Spouse/Partner
- Siblings
- Children
- Grandchildren

Click on any family member's name to view their family tree.

## Model Methods

### User Model

The User model includes many helper methods:

#### Direct Relationships
```ruby
user.parents                    # All parents
user.children                   # All children
user.siblings                   # All siblings
user.spouses(include_ex: true)  # All spouses/partners
user.current_spouse             # Current active spouse
```

#### Extended Family
```ruby
user.grandparents               # Parents' parents
user.grandchildren              # Children's children
user.aunts_and_uncles          # Parents' siblings
user.nieces_and_nephews        # Siblings' children
user.cousins                   # Parents' siblings' children
```

#### Recursive Methods
```ruby
user.ancestors(generations: 3)  # All ancestors, optionally limited
user.descendants(generations: 2) # All descendants, optionally limited
```

#### Utility Methods
```ruby
user.all_family_members         # Everyone related
user.related_to?(other_user)    # Check if related
user.deceased?                  # Check if deceased
user.age                        # Current age or age at death
```

### Relationship Model

#### Scopes
```ruby
Relationship.parents            # Parent relationships
Relationship.children           # Child relationships
Relationship.spouses           # Spousal relationships
Relationship.siblings          # Sibling relationships
Relationship.active            # Active relationships
Relationship.ended             # Ended relationships
```

#### Instance Methods
```ruby
relationship.active?           # Is relationship currently active?
relationship.reciprocal_type   # Get the reciprocal relationship type
relationship.display_type      # Human-readable type
```

## Testing

The system includes comprehensive RSpec tests:

### Run All Tests
```bash
bundle exec rspec
```

### Run Model Tests
```bash
bundle exec rspec spec/models
```

### Run Controller Tests
```bash
bundle exec rspec spec/requests
```

### Test Coverage

- Relationship model validations and callbacks
- User model relationship methods
- Controller authorization and CRUD operations
- Reciprocal relationship creation/deletion
- Extended family calculations

## Example Usage in Controllers

```ruby
class MyController < ApplicationController
  def show
    @user = User.find(params[:id])

    # Get immediate family
    @parents = @user.parents
    @children = @user.children

    # Get extended family
    @grandparents = @user.grandparents

    # Get all ancestors up to 5 generations
    @ancestors = @user.ancestors(generations: 5)

    # Check relationships
    if @user.related_to?(current_user)
      # They're related!
    end
  end
end
```

## Example Usage in Views

```erb
<h2>Parents</h2>
<ul>
  <% @user.parents.each do |parent| %>
    <li>
      <%= link_to parent.display_name, user_family_tree_path(parent) %>
      <% if parent.deceased? %>
        <span class="badge">Deceased</span>
      <% end %>
    </li>
  <% end %>
</ul>

<h2>Spouse</h2>
<% if @user.current_spouse %>
  <p><%= link_to @user.current_spouse.display_name, user_family_tree_path(@user.current_spouse) %></p>
<% end %>
```

## Performance Considerations

### Eager Loading

When querying relationships, use eager loading to prevent N+1 queries:

```ruby
# Bad - causes N+1 queries
user.parents.each { |p| puts p.display_name }

# Good - eager loads
user.relationships.parents.includes(:relative).map(&:relative)
```

### Caching

For expensive operations like ancestor/descendant calculations:

```ruby
# In User model
def cached_ancestors
  Rails.cache.fetch("user_#{id}_ancestors", expires_in: 1.hour) do
    ancestors
  end
end
```

### Database Indexes

The system includes optimized indexes for:
- Looking up relationships by user
- Reverse lookups (finding who is related to a user)
- Filtering by relationship type

## Future Enhancements

Potential improvements to consider:

1. **Materialized Path**: For very large family trees, consider using a closure table or materialized path for faster ancestor/descendant queries

2. **Visualization**: Add a graphical tree visualization using D3.js or similar

3. **Privacy Levels**: Add granular privacy controls for who can see which relationships

4. **Verification**: Add a verification system where both parties must approve a relationship

5. **Family Groups**: Create family groups or branches for better organization

6. **Import/Export**: Add GEDCOM import/export for compatibility with other genealogy software

## Troubleshooting

### Issue: Relationships not appearing
- Check that you're logged in
- Verify the relationship was created (check database)
- Ensure reciprocal relationship was created

### Issue: Can't edit/delete relationship
- Verify you're either the creator (user_id) or participant (relative_id)
- Check authentication status

### Issue: Performance problems with large trees
- Implement caching for recursive methods
- Consider limiting the depth of ancestor/descendant queries
- Add database indexes if needed

## Support

For issues or questions:
1. Check the test files for usage examples
2. Review the model code for available methods
3. Check Rails logs for error messages
