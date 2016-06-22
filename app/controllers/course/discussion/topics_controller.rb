# frozen_string_literal: true
class Course::Discussion::TopicsController < Course::ComponentController
  before_action :check_component
  load_and_authorize_resource :discussion_topic, through: :course, instance_name: :topic,
                                                 class: Course::Discussion::Topic.name,
                                                 parent: false
  before_action :load_settings
  before_action :add_topics_breadcrumb

  def index
    @topics = all_topics

    if current_course_user && current_course_user.student?
      @topics = @topics.from_user(current_course_user.user_id)
    end
  end

  def pending
    @topics = all_topics.pending_staff_reply
  end

  def my_students
    @topics = my_students_topics
  end

  def my_students_pending
    @topics = my_students_topics.pending_staff_reply
  end

  private

  def all_topics
    @topics.globally_displayed.ordered_by_updated_at.includes(:actable).page(page_param).
      per(@settings.pagination)
  end

  def my_students_topics
    my_student_ids = current_course_user ? current_course_user.my_students.pluck(:user_id) : []
    @topics = @topics.
              globally_displayed.
              ordered_by_updated_at.
              from_user(my_student_ids).
              includes(:actable).
              page(page_param)
  end

  # Ensure that the component is enabled.
  #
  # @raise [Coursemology::ComponentNotFoundError] When the component is disabled.
  def check_component
    raise ComponentNotFoundError unless component
  end

  def load_settings
    @settings = component.settings
  end

  def add_topics_breadcrumb
    add_breadcrumb @settings.title || :index, :course_topics_path
  end

  def component
    current_component_host[:course_discussion_topics_component]
  end
end
