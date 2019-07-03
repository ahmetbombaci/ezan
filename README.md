#Ezan (Call for prayer)

Make Ezan (Call for prayer) available at your home. 


## HomeAssistant Configuration

### Install HomeAssistant

If you have home assistant, you may skip this step.

`docker run --init -d --name="home-assistant" -v YOUR_LOCAL_PATH_FOR_HOME_ASSISTANT:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant`

When this is completed, you can access admin portal from http://localhost:8123

Follow the instructions and create an admin user, set the password.

During HomeAssistant installation, it will detect devices so do not forget to add them.

### Long_Lived Access Token

Go to http://localhost:8123/profile

Create a token

Copy token value to `./script/homeAssistant.api.token` file.

Verify that home assistant api is working with generated token:
`curl --silent -X GET -H "Authorization: Bearer YOUR_TOKEN_IS_HERE" \
 -H "Content-Type: application/json" http://localhost:8123/api/states`

### Create new automation

http://localhost:8123/config/automation/new

+ Name: `Ezan`
+ Trigger
	+ Trigger Type: `Event`
	+ Event Type: `ezan`
+ Actions
	+ Action Type: `Call service`
	+ Service: `media_player.play_media`
	+ Service data: `{
                       "entity_id": "media_player.living_room_display",
                       "media_content_id": "http://192.168.0.15:8080/ezan.mp3",
                       "media_content_type": "audio/mp4"
                     }`

Make sure that `entity_id` matches the name of your home smart device
Update `192.168.0.15` in `media_content_id` with your local ip address. Use `ifconfig` to get local ip address.



## How to run

Run `docker-compose up`

The following containers will be launched:
* `home-file-server`: Local file server that will serve Ezan in mp3 format
* `ezan-scheduler`: Job scheduler

Ezan scheduler will call prayer times api once a day during midnight to get pray times. Then, jobs will be scheduled to be executed during pray time which will fire ezan event.


