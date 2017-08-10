puts "*"*80
puts "::: Creating Security Questions:::"

created_count = 0

DEFAULT_QUESTIONS = [
  "What is your all time favorite singer?",
  "What was the frist street you lived on? ",
  "What was you first sweetheart's first name?",
  "Who is you favorite athlete?",
  "What was the color of first cat?",
  "What is the first name mother's oldest sibling?",
  "What was the name of your favorite teacher?",
  "What is the first name of first famous person you met?",
  "What is your youngest child's nickname?",
  "What was your first job?",
  "What is your all time favorite autmobile?",
  "What is the name of your favorite musical group?",
  "What was your father's profession when you were born?",
  "What was your first sweetheart's last name?",
  "What city was your favorite Olympic games played in?"
]

DEFAULT_QUESTIONS.each do |question|
  security_question = SecurityQuestion.find_or_initialize_by(title: question)
  security_question.visible = true
  if security_question.save!
    created_count = created_count + 1
  end
end

puts "Created or updated #{created_count} security questions"
