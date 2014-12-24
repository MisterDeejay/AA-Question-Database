require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  attr_reader :id

  def self.find_by_id(search_id)
    query = <<-SQL
    SELECT
    *
    FROM
    users
    WHERE
    id = ?
    SQL
    user_data = QuestionsDatabase.instance.execute(query, search_id)
    user_data.map {|user| User.new(user) }.first
  end

  def self.find_by_name(search_fname, search_lname)
    query = <<-SQL
    SELECT
    *
    FROM
    users
    WHERE
    fname = ? AND lname = ?
    SQL
    user_data = QuestionsDatabase.instance.execute(query, search_fname, search_lname)
    user_data.map {|user| User.new(user) }.first
  end

  def authored_questions
    query = <<-SQL
      SELECT
        questions.id
      FROM
        users
      INNER JOIN
        questions
      ON
        users.id = questions.author_id
      WHERE
        users.id = ?
    SQL
    questions_data = QuestionsDatabase.instance.execute(query, self.id)
    questions_data.map do |id|
      id.each_value { |value| Question.find_by_id(value) }
    end
  end


  def authored_replies
    query = <<-SQL
    SELECT
    replies.id
    FROM
    users
    INNER JOIN
    replies
    ON
    users.id = replies.author_id
    WHERE
    users.id = ?
    SQL
    questions_data = QuestionsDatabase.instance.execute(query, self.id)
    questions_data.map do |id|
      id.each_value { |value| Reply.find_by_id(value) }
    end
  end

  def followed_questions
    QuestionFollower::find_by_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    query <<-SQL
    SELECT
    COUNT(question_likes.id) / COUNT(DISTINCT(questions.id))
    FROM
    questions_likes
    LEFT OUTER JOIN
    questions
    ON
    questions.id = question_likes.question_id
    GROUP BY
    questions.user_id
    WHERE
    question.user_id = ?
    SQL
    average_karma = QuestionsDatabase.instance.execute(query, @id)
  end

  def initialize options
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end
class Question
  attr_reader :author_id, :id, :title, :body
  def self.find_by_id(search_id)
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    WHERE
    id = ?
    SQL
    questions_data = QuestionsDatabase.instance.execute(query, search_id)
    questions_data.map {|question| Question.new(question) }.first
  end

  def self.find_by_title(search_title)
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    WHERE
    title = ?
    SQL
    question_data = QuestionsDatabase.instance.execute(query, search_title)
    question_data.map {|question| Question.new(question) }.first
  end

  def self.find_by_body(search_body)
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    WHERE
    body = ?
    SQL
    question_data = QuestionsDatabase.instance.execute(query, search_body)
    question_data.map {|question| Question.new(question) }.first
  end

  def self.find_by_author_id(search_author_id)
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    WHERE
    author_id = ?
    SQL
    question_data = QuestionsDatabase.instance.execute(query, search_author_id)
    question_data.map {|question| Question.new(question) }.first
  end

  def author
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    JOIN
    users
    ON
    users.id = questions.author_id
    WHERE
    questions.author_id = ?
    SQL
    users_data = QuestionsDatabase.instance.execute(query, self.author_id)
    users_data.map { |user| User.new(user) }
  end

  def replies
    query = <<-SQL
    SELECT
    *
    FROM
    questions
    JOIN
    replies
    ON
    replies.question_id = questions.id
    WHERE
    questions.id = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, self.id)
    replies_data.map { |reply| Reply.new(reply) }
  end
###Not Working
  def followers
    QuestionFollower::find_by_question_id(@id)
  end
###Not Working
  def self.most_followed(n)
    QuestionFollower::most_followed_question(n)
  end

###Not Working
  def likers
    QuestionLike.likers_for_question_id(@id)
  end
###Not Working
  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked_questions(n)
    query =<<-SQL
    SELECT
    question_id
    FROM
    question_likes
    JOIN
    questions
    ON
    questions.id = question_likes.question_id
    GROUP BY
    questions.id
    ORDER BY
    COUNT(questions.id)
    SQL
    question_ids = QuestionsDatabase.instance.execute(query)
    p question_id
    question_ids.map { |question_id| Question.find_by_id(question_id) }.take(n)
  end

  def initialize options
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

end
class QuestionFollower
  attr_reader :id, :user_id, :question_id, :author_id

  def self.find_by_user_id(search_user_id)
    query = <<-SQL
    SELECT
    *
    FROM
    question_followers
    WHERE
    user_id = ?
    SQL
    question_followers = QuestionsDatabase.instance.execute(query, search_user_id)
    question_followers.map {|question_follower| Question.new(question_follower) }
  end

  def self.find_by_question_id(search_question_id)
    query = <<-SQL
    SELECT
    *
    FROM
    question_followers
    WHERE
    question_id = ?
    SQL
    question_followers = QuestionsDatabase.instance.execute(query, search_question_id)
    question_followers.map {|question_follower| Question.new(question_follower) }
  end

  def self.most_followed_question(n)
    query = <<-SQL
    SELECT
    *
    FROM
    question_followers
    GROUP BY
    question_id
    ORDER BY
    COUNT(user_id)
    WHERE
    question_id = ?
    SQL
      questions_data = QuestionsDatabase.instance.execute(query, self.question_id)
      questions_data.map { |question| Question.new(question)}.shift(n)
  end


  def initialize options
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @author_id = options['author_id']
  end
end
class Reply
  attr_reader :id, :author_id, :body, :question_id
  def self.find_by_id(search_id)
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    WHERE
    id = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, search_id)
    replies_data.map {|question| Reply.new(question) }.first
  end

  def self.find_by_question_id(search_question_id)
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    WHERE
    question_id = ?
    SQL
    replies = QuestionsDatabase.instance.execute(query, search_question_id)
    replies.map {|reply| Reply.new(reply) }.first
  end

  def self.find_by_author_id(search_author_id)
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    WHERE
    author_id = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, search_author_id)
    replies_data.map {|reply| Reply.new(reply) }.first
  end

  def self.find_by_body(search_body)
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    WHERE
    body = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, search_body)
    replies_data.map {|reply| Reply.new(reply) }.first
  end

  def self.find_by_body(search_body)
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    WHERE
    body = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, search_body)
    replies_data.map {|reply| Reply.new(reply) }.first
  end

  def author
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    JOIN
    users
    ON
    users.id = replies.author_id
    WHERE
    author_id = ?
    SQL
    users_data = QuestionsDatabase.instance.execute(query, self.author_id)
    users_data.map {|user| User.new(user) }.first
  end

  def question
    query = <<-SQL
    SELECT
    *
    FROM
    replies
    JOIN
    questions
    ON
    questions.id = replies.question_id
    WHERE
    question_id = ?
    SQL
    questions_data = QuestionsDatabase.instance.execute(query, self.question_id)
    questions_data.map {|question| Question.new(question) }.first
  end

  def parent_reply
    query = <<-SQL
    SELECT
    *
    FROM
    replies r1
    JOIN
    replies r2
    ON
    r1.parent_reply = r2.id
    WHERE
    r1.parent_reply = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, @parent_reply)
    # replies_data.map {|reply| Reply.new(reply) }.first
  end

  def child_replies
    query = <<-SQL
    SELECT
    *
    FROM
    replies r1
    JOIN
    replies r2
    ON
    r1.id = r2.parent_reply
    WHERE
    r1.id = ?
    SQL
    replies_data = QuestionsDatabase.instance.execute(query, self.id)
    replies_data.map {|reply| Reply.new(reply) }
  end

  def initialize options
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply = options['parent_reply']
    @author_id = options['author_id']
    @body = options['body']
  end
end

class QuestionLike
  attr_reader :id, :question_id, :user_id

  def self.find_by_id(search_id)
    query = <<-SQL
    SELECT
    *
    FROM
    question_likes
    WHERE
    id = ?
    SQL
    question_likes_data = QuestionsDatabase.instance.execute(query, search_id)
    question_likes_data.map { |question_like| QuestionLike.new(question_like) }.first
  end

  def self.likers_for_question_id(question_id)
    query = <<-SQL
    SELECT
    user_id
    FROM
    question_likes
    JOIN
    questions
    ON
    question_likes.question_id = questions.id
    WHERE
    question_likes.question_id = ?
    SQL
    question_likers_data = QuestionsDatabase.instance.execute(query, @question_id)
    question_likers_data.map { |user_id| User.find_by_id(user_id) }
  end

  def self.num_likes_for_question_id(question_id)
    query = <<-SQL
    SELECT
    COUNT(*)
    FROM
    question_likes
    JOIN
    questions
    ON
    question_likes.question_id = questions.id
    WHERE
    question_likes.question_id = ?
    GROUP BY
    question_likes.question_id
    SQL
    question_likers_data = QuestionsDatabase.instance.execute(query, @question_id)
    question_likers_data.map { |user_id| User.find_by_id(user_id) }.first
  end

  def self.liked_questions_for_user_id(user_id)
    query = <<-SQL
    SELECT
    question_id
    FROM
    question_likes
    JOIN
    questions q
    ON
    q.id = question_likes.question_id
    WHERE
    q.author_id = ?
    SQL
    questions_data = QuestionsDatabase.instance.execute(query, user_id)
    questions_data.map { |question| Question.find_by_id(question_id ) }
  end

  def initialize options
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end
