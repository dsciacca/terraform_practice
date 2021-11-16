variable "db_password" {
  description = "The password for the database"
}

variable "db_name" {
  description = "The name of the database"
}

variable "db_username" {
  description = "The name of the initial database user"
}

variable "instance_class" {
  description = "The database instance class to use"
}

variable "allocated_storage" {
  description = "The amount of storage to allocate for the Database"
}