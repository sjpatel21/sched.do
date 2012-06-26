Feature: User can create an event

  Scenario: User creates event
    Given I am signed in
    When I create an event named "Clown party" with a suggestion of "lunch"
    Then I should see an event named "Clown party" with a suggestion of "lunch"

  # This spec will occasionally fail, and I don't know why! This is somehow
  # related to Capybara and the javascript sometimes not being executed.
  # The issue lies in, or around the following, which does not seem to be waiting.
  # EventCreation::NestedFieldsSection#wait_for_primary_fields_to_update
  @javascript
  Scenario: User creates event with multiple suggestions
    Given I am signed in
    When I create an event with the following suggestions:
      | breakfast |           |
      | lunch     | chipotle  |
      | lunch     | boloco    |
      | lunch     | moes      |
      | dinner    |           |
    Then I should see an event with the following suggestions in order:
      | breakfast |           |
      | lunch     | chipotle  |
      | lunch     | boloco    |
      | lunch     | moes      |
      | dinner    |           |

  @javascript
  Scenario: User adds an additional suggestion field
    Given I sign in and fill in the event name
    When I add another suggestion field
    And I fill out the event form with the following suggestions:
      | breakfast |
      | lunch     |
      | dinner    |
    And I submit the create event form
    Then I should see an event with the following suggestions in order:
      | breakfast |
      | lunch     |
      | dinner    |

  @javascript
  Scenario: User removes a suggestion field
    Given I sign in and fill in the event name
    When I fill out the event form with the following suggestions:
      | breakfast |
      | lunch     |
    And I remove the first suggestion
    And I submit the create event form
    Then I should see an event with the following suggestions in order:
      | lunch     |

  Scenario: User sees multiple suggestions after filling in invalid data
    Given I am signed in
    When I try to create an event with invalid data
    Then I should see multiple suggestions

  Scenario: User sees event link after creating event
    Given I am signed in
    When I create an event
    Then I should see a link to that event
