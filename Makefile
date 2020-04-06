#Obiba Drupal Modules installation

SHELL := /bin/bash
#backup folder
CURRENT_TIME=$(shell date +"%Y-%m-%d-%H-%M-%S")
BACKUP_FOLDER=backups/drupal8-${CURRENT_TIME}
#mysql
MYSQL_HOST=localhost
MYSQL_DATABASE_USER=drupal
MYSQL_PASSWORD=1234
MYSQL_DB=drupal8
#Drupal
DRUPAL_VERSION=8.8.1
DRUPAL_FOLDER=target/drupal8
WEB_DRUPAL_FOLDER=$(DRUPAL_FOLDER)
CUSTOM_MODULE_DRUPAL_FOLDER=$(DRUPAL_FOLDER)/modules/custom
DF=drupal-release
Dadm=administrator
Dpassword=password
www_user="www-data"

backup-installation : backup-folder

build-obiba: drupal-get-source create-sql site-install link-projects enable-modules setting-conf copy-files clear-cache download-js-libraries download-bootstrap-theme import-config fix-permission clear-cache

drupal-get-source:
	composer create-project drupal/drupal:$(DRUPAL_VERSION) $(DRUPAL_FOLDER) --no-interaction

create-sql:
	mysql -h $(MYSQL_HOST) -u $(MYSQL_DATABASE_USER) --password=$(MYSQL_PASSWORD) -e "drop database if exists $(MYSQL_DB); create database $(MYSQL_DB) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

site-install:
	cd $(DRUPAL_FOLDER) && \
	drush site-install standard --account-name=$(Dadm) --account-pass=$(Dpassword) --db-url=mysql://$(MYSQL_DATABASE_USER):$(MYSQL_PASSWORD)@$(MYSQL_HOST)/$(MYSQL_DB) --site-name="Obiba Mica" -y

link-projects:
	mkdir $(CUSTOM_MODULE_DRUPAL_FOLDER) && \
	cd $(CUSTOM_MODULE_DRUPAL_FOLDER) && \
	ln -s ~/projects/mica-drupal8 obiba_mica && \
	ln -s ~/projects/agate-drupal8 obiba_agate

enable-modules:
	cd $(DRUPAL_FOLDER) && \
	drush en -y obiba_mica -y && \
	drush en -y obiba_mica_angular_app -y && \
	drush en -y obiba_agate -y && \
	drush en -y migrate_upgrade

copy-files:
	cp config/files/* $(WEB_DRUPAL_FOLDER)/sites/default/files/

clear-cache:
	cd $(DRUPAL_FOLDER) && \
	drush cr all

download-js-libraries:
	cd $(DRUPAL_FOLDER) && \
	mkdir libraries && \
	drush download-js -y

download-bootstrap-theme:
	cd $(DRUPAL_FOLDER) && \
	drush en -y bootstrap && \
	drush config-set system.theme default bootstrap -y

# Have to be absolut path
import-config:
	cd $(DRUPAL_FOLDER) && \
	drush config-import --partial --source=$(PWD)/config/sync -y


setting-conf:
	chmod 777 $(DRUPAL_FOLDER)/sites/default && \
	chmod 777 $(DRUPAL_FOLDER)/sites/default/settings.php && \
	echo "include 'settings.custom.php';" >> $(DRUPAL_FOLDER)/sites/default/settings.php && \
	cp config/settings.custom.php  $(WEB_DRUPAL_FOLDER)/sites/default/

fix-permission:
	chmod +rx $(DRUPAL_FOLDER)/sites/default && \
	chmod +rw $(DRUPAL_FOLDER)/sites/default/*.* && \
	chmod 444 $(DRUPAL_FOLDER)/sites/default/settings.php && \
	chmod 444 $(DRUPAL_FOLDER)/sites/default/settings.custom.php && \
	chmod 777 -R $(DRUPAL_FOLDER)/sites/default/files && \
	sudo chown -R $(www_user): $(DRUPAL_FOLDER)

backup-folder:
	mkdir $(BACKUP_FOLDER) && \
	cd $(DRUPAL_FOLDER) && \
	drush archive-dump default --destination=$(PWD)/$(BACKUP_FOLDER)/mysite.tar -y

drupal-export-config:
	cd $(DRUPAL_FOLDER) && \
	drush config-export -y
