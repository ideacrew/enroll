<template>
  <div class="ma-2">
      <h1 class="display-1">Employee Detail</h1>

      <v-container fluid grid-list-md>
        <v-layout row class="mt-3">
          <v-flex>
            <div class="headline">Details</div>
          </v-flex>
        </v-layout>
        <v-layout row class="mt-3">
          <v-flex>
            <v-card class="pa-3">
              <v-layout>
                <v-flex d-block>
                  <div class="subheading grey--text">First Name</div>
                  <div>Tony</div>
                </v-flex>
                <v-flex d-block>
                  <div class="subheading grey--text">Last Name</div>
                  <div>Schaffert</div>
                </v-flex>
              </v-layout>
            </v-card>
          </v-flex>
        </v-layout>
        <v-layout row class="mt-3">
          <v-flex xs6>
            <div class="headline">Address</div>
          </v-flex>
          <v-flex xs6>
            <div class="headline">Email</div>
          </v-flex>
        </v-layout>
        <v-layout row class="mt-3">
          <v-flex xs6>
            <v-card class="pa-3">
              <v-layout>
                <v-flex d-block>
                  <div class="subheading grey--text">Address 1</div>
                  <div>812 Cattail Ct</div>
                </v-flex>
                <v-flex d-block>
                  <div class="subheading grey--text">Address 2</div>
                  <div></div>
                </v-flex>
              </v-layout>
              <v-layout>
                <v-flex d-block>
                  <div class="subheading grey--text">City</div>
                  <div>Melbourne</div>
                </v-flex>
                <v-flex d-block>
                  <div class="subheading grey--text">State</div>
                  <div>Florida</div>
                </v-flex>
                <v-flex d-block>
                  <div class="subheading grey--text">Zip</div>
                  <div>32904</div>
                </v-flex>
              </v-layout>
            </v-card>
          </v-flex>
          <v-flex xs6>
            <v-card class="pa-3">
              <v-layout>
                <v-flex d-block>
                  <div class="subheading grey--text">Email</div>
                  <div>antonio.schaffert@gmail.com</div>
                </v-flex>
              </v-layout>
            </v-card>
          </v-flex>

          </v-flex>
        </v-layout>

      </v-container>

      <p>{{ $route.params.census_employee_id }}</p>

      <v-btn @click="$router.go(-1)" fab dark color="red"><v-icon>keyboard_arrow_left</v-icon></v-btn>
  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false
    }
  }
}
</script>

<style>
</style>
