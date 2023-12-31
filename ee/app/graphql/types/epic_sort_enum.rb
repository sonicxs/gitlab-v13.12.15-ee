# frozen_string_literal: true

module Types
  class EpicSortEnum < BaseEnum
    graphql_name 'EpicSort'
    description 'Roadmap sort values'

    # Deprecated, as we prefer uppercase enums
    # https://gitlab.com/groups/gitlab-org/-/epics/1838
    value 'start_date_desc', 'Start date at descending order.', value: :start_date_desc, deprecated: { reason: 'Use START_DATE_DESC', milestone: '13.11' }
    value 'start_date_asc', 'Start date at ascending order.', value: :start_date_asc, deprecated: { reason: 'Use START_DATE_ASC', milestone: '13.11' }
    value 'end_date_desc', 'End date at descending order.', value: :end_date_desc, deprecated: { reason: 'Use END_DATE_DESC', milestone: '13.11' }
    value 'end_date_asc', 'End date at ascending order.', value: :end_date_asc, deprecated: { reason: 'Use END_DATE_ASC', milestone: '13.11' }

    value 'START_DATE_DESC', 'Sort by start date in descending order.', value: :start_date_desc
    value 'START_DATE_ASC', 'Sort by start date in ascending order.', value: :start_date_asc
    value 'END_DATE_DESC', 'Sort by end date in descending order.', value: :end_date_desc
    value 'END_DATE_ASC', 'Sort by end date in ascending order.', value: :end_date_asc
  end
end
