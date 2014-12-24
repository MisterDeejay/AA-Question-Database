CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply INTEGER,
  author_id INTEGER NOT NULL,
  body VARCHAR(255) NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES user(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('john', 'doe'),
  ('jane', 'ridley'),
  ('the', 'rock'),
  ('johnny', 'bravo'),
  ('spongebob', 'squarepants');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('sky color?', "What color is the sky?", (SELECT id from users WHERE fname = 'john' AND lname = 'doe')),
  ('fruit color?', "What color is an orange?", (SELECT id from users WHERE fname = 'the' AND lname = 'rock')),
  ('earth age?', "How old is the earth?", (SELECT id from users WHERE fname = 'johnny' AND lname = 'bravo')),
  ('height', "How tall are you?", (SELECT id from users WHERE fname = 'john' AND lname = 'doe')),
  ('birthday?', "When is your birthday?", (SELECT id from users WHERE fname = 'john' AND lname = 'doe')),
  ('math question', "What is 2 + 2?", (SELECT id from users WHERE fname = 'jane' AND lname = 'ridley'));

INSERT INTO
  replies (question_id, parent_reply, author_id, body)
VALUES
  ((SELECT id from questions WHERE title = 'sky color?' ),
  null,
   (SELECT id from users WHERE fname = 'john' AND lname = 'doe'),
    "Dang that is fascinating"),

  ((SELECT id from questions WHERE title = 'sky color?' ),
  1,
  (SELECT id from users WHERE fname = 'johnny' AND lname = 'bravo'),
  "You're an idiot"),

  ((SELECT id from questions WHERE title = 'fruit color?' ),
  null,
  (SELECT id from users WHERE fname = 'the' AND lname = 'rock'),
  "orange, buddy"),

  ((SELECT id from questions WHERE title = 'sky color?' ),
  1,
  (SELECT id from users WHERE fname = 'jane' AND lname = 'ridley'),
  "you're a troll"),

  ((SELECT id from questions WHERE title = 'math question' ),
  null,
  (SELECT id from users WHERE fname = 'spongebob' AND lname = 'squarepants'),
  "i think it's 6");
INSERT INTO
  question_followers (user_id, question_id)
VALUES
  ((SELECT id from users WHERE fname = 'johnny' AND lname = 'bravo'),
    (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'spongebob' AND lname = 'squarepants'),
    (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'john' AND lname = 'doe'),
    (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'the' AND lname = 'rock'),
    (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'jane' AND lname = 'ridley'),
    (SELECT id from questions WHERE title = 'sky color?'));

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  ((SELECT id from users WHERE fname = 'johnny' AND lname = 'bravo'),
  (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'spongebob' AND lname = 'squarepants'),
  (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'john' AND lname = 'doe'),
  (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'the' AND lname = 'rock'),
  (SELECT id from questions WHERE title = 'sky color?')),
  ((SELECT id from users WHERE fname = 'jane' AND lname = 'ridley'),
  (SELECT id from questions WHERE title = 'sky color?'));
