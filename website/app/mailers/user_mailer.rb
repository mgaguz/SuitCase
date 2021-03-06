class UserMailer < ApplicationMailer

  def welcome_email(user)
    @user = user
    mail(from: 'suitcasemailer@gmail.com', to: @user.email, subject: 'Welcome to SuiteCase!')
  end

  def notification_email(notification)
    @user = notification.user
    @notification = notification
    mail(from: 'suitcasemailer@gmail.com', to: @user.email, subject: 'Suitcase - New Notification!')
  end

end
