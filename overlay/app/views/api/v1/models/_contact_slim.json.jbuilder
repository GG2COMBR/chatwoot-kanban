return if resource.blank?

json.id resource.id
json.name resource.name
json.email resource.email
json.phone_number resource.phone_number
json.thumbnail resource.avatar_url
json.identifier resource.identifier
json.custom_attributes resource.custom_attributes
json.additional_attributes resource.additional_attributes
