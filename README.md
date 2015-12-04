# Entity UI

Entity UI is a JS GUI framework for rapid development of business-applications based on simple metadata describing data structure of the application.

Application data structure is supposed to be a set of linked entities. Framework generates a table view and a form view for entity on demand.

Entity form has **master-detail** structure with fields for entity attributes and tabs for **downlinks** containing tables of linked instances of entities-descendants generated authomatically based on their metadata. Some form fields have type of **uplink** and contain references to instances of parent entities.

## Usecase

A typical **usecase** is as follows:

* Some root entity table is placed somewhere in the html DOM element:

```javascript
$("#id_of_div_where_to_place_root_table").EntUI("entity_name");
```

* Double-click on table row opens a modal window containing form with data
* Double-click on uplink field in the form opens next window which contains
	* a form of linked parent entity if uplink field contains data
	* a table of linked parent entity (in a modal window) for link selection if uplink contains no data and is editable
* Double-click on a downlink table row opens window containing form with instance of corresponding instance of entity-descendant

So user can walk freely through any linked data up and down, and it does not require any extra code provided that metadata of linked entities is available.

**IMPORTANT NOTES:**

* All forms and tables are build on demand, i.e. when user double-clicks row or uplink
* There is no restriction of link depth so user can open as many windows or tables as needs

## Customization

One can register callbacks for building, drawing and editing events of entity tables and forms. So it allows customizing look and behavior of widgets, changing data and controls, adding new elements and so on.

## Server side

Entity UI gets entity data through AJAX-requests with simple API as follows:
* Getting metadata by entity name
* Getting data for entity table (with paging, filtering, sorting and parent parameters)
* Getting data for entity table filters (described in metadata)
* Getting data for entity form by entity name and id
* Saving entity form data

We will provide a RubyOnRails sample data server application for Entity UI including:
* Sample models containing metadata 
* Generic DataController serving Entity UI data API

We also plan to develop an utility for complete autogeneration of Rails application with generic Enity UI frontend and generic DataController backend based on existing database.

## Dependencies

Entity UI uses following external libraries:

* jQuery
* jQuery UI
* jQuery plugins: 
	* DataTables, 
	* DatePicker
* underscore.js

