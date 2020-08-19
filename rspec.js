const { promises: fs } = require("fs");

async function getJson() {
  const response = await fs.readFile("./ci/small-report.json", "utf-8");

  const { type, features } = JSON.parse(response);

  const filteredFeatures = features.filter((feature) => {
    const state = feature.properties.STATE;

    return (
      state === "09" ||
      state === "10" ||
      state === "11" ||
      state === "12" ||
      state === "24" ||
      state === "34" ||
      state === "36" ||
      state === "42" ||
      state === "51" ||
      state === "54"
    );
  });

  const featuresWithFips = filteredFeatures.map((feature) => {
    const { type, properties, geometry } = feature;

    const updatedProperties = {
      ...properties,
      fips: `${properties.STATE}${properties.COUNTY}`,
    };

    return {
      type,
      geometry,
      properties: updatedProperties,
    };
  });

  const geojson = { type, features: featuresWithFips };

  const jsonList = JSON.stringify(geojson);

  await fs.writeFile("./public/mtb-counties.geo.json", jsonList);
}

getJson();
