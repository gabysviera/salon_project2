#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\nWelcome to Gaby'salon!\n""\nAre you ready to become the best version of yourself?"

MAIN_MENU() {
 if [[ $1 ]] 
then
 echo $1 
 fi
echo -e "\n\nPlease, take an option:"
echo -e "\n1) GET A LOOK""\n2) CANCEL THE APPOINTMENT""\n3) EXIT"
read OPTION_MENU

case $OPTION_MENU in 
  1) GET_A_LOOK ;;
  2) CANCEL_THE_APPOINTMENT ;;
  3) EXIT ;;
  *) MAIN_MENU "Sorry. Invalid option." ;;
  esac
}

GET_A_LOOK() {
   echo -e "\n~Let's get a look~. What would you like to do?"
   GET_SERVICES=$($PSQL "SELECT service_id, name FROM services")
   echo "$GET_SERVICES" | while read SERVICE_ID BAR NAME
   do
   echo "$SERVICE_ID) $NAME"
done
   read SERVICE_ID_SELECTED
   
   #if it is not a number:
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]$ ]]
  then
   #send to main menu
   MAIN_MENU "Sorry. Invalid option"
  else
  #check if the option is on the database. First, get the info from the database
  GET_SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")
  if [[ -z $SERVICE_ID_SELECTED ]]
  then
  MAIN_MENU "Sorry. Invalid option"
  else
   echo -e "\nPlease, enter your phone number"
   read CUSTOMER_PHONE
   #check if the customer name exists in the customers table:
   CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    # if the user doesn't exist:
   if [[ -z $CUSTOMER_NAME ]]
   then
   #ask customers name:
   echo "Please, let me know your name:"
   read CUSTOMER_NAME 
   #add the user
   ADD_CUSTOMER_NAME=$($PSQL "INSERT INTO customers(name,phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
   #get customer name
   CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
   fi
   # if the user exists, show available hours to book:
   
    GET_TIME_APPOINTMENT=$($PSQL "SELECT appointment_id, time FROM appointments WHERE available = true ORDER BY appointment_id")
    #if there is no available times
   if [[ -z $GET_TIME_APPOINTMENT ]]
   then
   MAIN_MENU "Sorry, we don't have any time available for today. Please, try later!"
   else
   #let the user choose the best time to book:
   echo "Please, $CUSTOMER_NAME, choose the best time for you to have the appointment:"
   echo "$GET_TIME_APPOINTMENT" | while read APPOINTMENT_ID BAR TIME 
   do
   echo "$APPOINTMENT_ID) $TIME"
   done

   read SERVICE_TIME
   # if the input is not a number or it is not a required number:
   if [[ ! $SERVICE_TIME =~ ^([0-9]|1[0-5])$ ]]
   then
   MAIN_MENU "Sorry, you put an invalid option"   
   else
   #get customer_id
   CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
   #insert the time and the customer in the table
   INSERT_TIME_TO_TABLE=$($PSQL "UPDATE appointments SET customer_id = '$CUSTOMER_ID', service_id = '$SERVICE_ID_SELECTED' WHERE appointment_id = '$SERVICE_TIME'")
  #put time in false to not be choose anymore until it becomes true again
   SERVICE_TIME_TO_FALSE=$($PSQL "UPDATE appointments SET available=false WHERE appointment_id='$SERVICE_TIME'")
   TIME=$($PSQL "SELECT time FROM appointments WHERE appointment_id = '$SERVICE_TIME'")
   SERVICE=$($PSQL "SELECT name FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")
   MAIN_MENU "I have put you down a $SERVICE at $TIME, $CUSTOMER_NAME"
  fi
  fi
  fi
  fi
}

CANCEL_THE_APPOINTMENT() {
#get customer info 
echo -e "\nPlease, put your phone number"
read CUSTOMER_PHONE
#check customer phone
GET_CUSTOMER_PHONE=$($PSQL "SELECT phone FROM customers WHERE phone = '$CUSTOMER_PHONE'")
#if not found
  if [[ -z $GET_CUSTOMER_PHONE ]]
  then
   #send to main menu
   MAIN_MENU "Sorry, we can't find a record for that phone number."   
else
#get appointments
CUSTOMER_APPOINTMENTS=$($PSQL "SELECT appointment_id, time FROM appointments INNER JOIN customers USING(customer_id) WHERE phone = '$CUSTOMER_PHONE' AND available = false")
#get customer_name
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
#check if there are appointments
if [[ -z $CUSTOMER_APPOINTMENTS ]]
then
echo -e "\nHello, $CUSTOMER_NAME! You don't have any appointment booked."
else
echo -e "\nHello,$CUSTOMER_NAME!"
echo -e "\n\n~~Appointment/s~~" "\nPlease,$CUSTOMER_NAME choose the appointment you would like to cancel:"
echo "$CUSTOMER_APPOINTMENTS" | while read APPOINTMENT_ID BAR TIME
do
echo "$APPOINTMENT_ID) $TIME"
done

read APPOINTMENT_BOOKED
  #if not a number
    if [[ ! $APPOINTMENT_BOOKED =~ ^[0-9]+$ ]]
    then
    # send to main menu
    MAIN_MENU "Sorry, that is an invalid option"    
   else
#check if input is booked
BOOK_ID=$($PSQL "SELECT appointment_id FROM appointments INNER JOIN customers USING(customer_id) WHERE phone='$CUSTOMER_PHONE' AND appointment_id = '$APPOINTMENT_BOOKED'")
#if input is not booked
if [[ -z $BOOK_ID ]]
then 
 #send to main menu '
MAIN_MENU "Sorry, we don't have any appointment under your name" 
else 
#set time availability to true 
SERVICE_TIME_TO_TRUE=$($PSQL "UPDATE appointments SET available = true WHERE appointment_id = '$APPOINTMENT_BOOKED'") 
#send to main menu 
MAIN_MENU "Excellent! Your appointment was cancel. Have a nice day!" 
fi 
fi 
fi 
fi 
}


EXIT() {
echo -e "\nThank you for stopping in!"
}


MAIN_MENU