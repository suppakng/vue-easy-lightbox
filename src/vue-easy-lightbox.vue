<template>
  <transition name="fade">
    <div
      v-if="visible"
      class="img-swiper modal"
      @click.self="closeDialog"
    >
      <loading :active.sync="loading" 
        :loader="dots" 
        :is-full-page="true">
      </loading>
      <div
        class="img-wrapper"
        :class="{transition: imgTransitionStatus}"
        :style="imgStyle"
      >
        <img
          class="img"
          :src="visibleImgSrc"
          alt=""
          draggable="false"
          @mousedown="handleMouseDown($event)"
          @mouseup="handleMouseUp($event)"
          @mousemove="handleMouseMove($event)"
        >
      </div>

      <!-- btns -->
        <div class="btns">
          <div
            v-if="imgList.length !== 1"
            class="btn__prev"
            :class="{disable: imgIndex === 0}"
            @click="prev"
          >
            <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-prev"></use>
            </svg>
          </div>

          <div
            v-if="imgList.length !== 1"
            class="btn__next"
            :class="{disable: imgIndex === imgList.length - 1}"
            @click="next"
          >
            <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-next"></use>
            </svg>
          </div>

          <div
            class="btn__close"
            @click="closeDialog"
          >
            <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-close"></use>
            </svg>
          </div>

          <div class="toolbar-btns">
            <!-- zoom-in -->
            <div
              class="toobar-btn toolbar-btn__zoomin"
              @click="zoomIn()"
            >
              <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-zoomin"></use>
              </svg>
            </div>

            <!-- zoom-out -->
            <div
              class="toobar-btn toolbar-btn__zoomout"
              @click="zoomOut()"
            >
              <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-zoomout"></use>
              </svg>
            </div>

            <!-- rotate -->
            <div
              class="toobar-btn toolbar-btn__rotate"
              @click="rotate()"
            >
              <svg class="icon" aria-hidden="true">
                <use xlink:href="#icon-rotate"></use>
              </svg>
            </div>
            <!-- add-pics -->
            <div
              class="toobar-btn toolbar-btn__rotate image-upload" style="font-size:30px !important;"
            >
              <label for="file-input" class = "icon">
                <div class="icon ti-folder"/>
              </label>              
              <input id="file-input" type="file" multiple :name="uploadFieldName" :disabled="isSaving" @change="filesChange($event.target.name, $event.target.files); fileCount = $event.target.files.length"
              accept="image/*" class="input-file">
            </div>
            <!-- remove-pics -->
            <div
              class="toobar-btn toolbar-btn__rotate" style="font-size:30px !important;"
            >
              <div class="icon ti-trash" aria-hidden="true" @click="remove()">
              </div>
            </div>
          </div>
        </div>

        <!-- total -->
        <div
          v-if="imgList.length !== 1"
          class="pagination-total"
        >{{ imgIndex + 1 }}/{{ imgTotal }}</div>
    </div>
  </transition>
</template>

<script>
  import './assets/svg/iconfont'
  import axios from 'axios'
  // Import component
  import Loading from 'vue-loading-overlay'
  import swal from 'sweetalert2'

  // For File upload delete after
  const STATUS_INITIAL = 0
  const STATUS_SAVING = 1
  const STATUS_SUCCESS = 2
  const STATUS_FAILED = 3
  export default {
    name: 'vue-easy-lightbox',
    components: {
      Loading
    },
    props: {
      metaData: {
        token: String,
        baseURL: String
      },
      imgs: {
        type: [Array, String]
      },
      visible: {
        type: Boolean
      },
      index: {
        type: Number,
        default: 0
      },
      propertyData: {}
    },
    data () {
      return {
        messageTypes: ['', 'info', 'success', 'warning', 'danger'],
        dots: 'dots',
        loading: true,
        dataReady: false,
        propData: {},
        scale: 1,
        rotateDeg: 0,
        imgIndex: 0,
        imgTransitionStatus: true,
        top: 0,
        left: 0,
        lastX: 0,
        lastY: 0,
        isDraging: false,
        images: [],
        rawImages: [],
        // FileUplaod
        uploadedFiles: [],
        uploadError: null,
        currentStatus: null,
        uploadFieldName: 'file'
      }
    },
    methods: {
      upload (formData) {
        this.loading = true
        const instance = this
        const token = this.metaData.token
        const BASE_URL = this.metaData.baseURL
        const url = `${BASE_URL}/files/upload?token=` + token + '&type=photos&id=' + this.propData.property_ID
        return axios.post(url, formData)
            .then(function (response) {
              console.log('Serious ', response)
              instance.refresh()
            })
            // get data
            .then(x => x.data)
            // add url field
            .then(x => x.map(img => Object.assign({},
                img, { url: `${BASE_URL}/images/${img.id}` })))
            .then(function(result) {
                console.log("finally");
            })
      },
      reset () {
        // reset form to initial state
        this.currentStatus = STATUS_INITIAL
        this.uploadedFiles = []
        this.uploadError = null
      },
      save (formData) {
        // upload data to the server
        this.currentStatus = STATUS_SAVING
        var instance = this
        this.upload(formData)
          .then(x => {
            this.uploadedFiles = [].concat(x)
            this.currentStatus = STATUS_SUCCESS
            console.log('wtf')
            instance.refresh()
          })
          .catch(err => {
            this.uploadError = err.response
            this.currentStatus = STATUS_FAILED
          })
      },
      filesChange (fieldName, fileList) {
        // handle file changes
        const formData = new FormData()

        if (!fileList.length) return

        // append the files to FormData
        Array
          .from(Array(fileList.length).keys())
          .map(x => {
            formData.append(fieldName, fileList[x], fileList[x].name)
          })

        // save it
        this.save(formData)
      },
      saveProperty  () {
        var url = ''
        var baseURL = this.metaData.baseURL
        const token = this.metaData.token
        console.log('updating property', this.images[0], this.propData.property_ID)
        var  url = baseURL + '/properties/updateProperty?token=' + token + '&property_ID=' + this.propData.property_ID + '&owner_ID=2&preview_URL=' + this.images[0] + '&address1=' + this.propData.address1 + '&address2=' + this.propData.address2 + '&city=' + this.propData.city + '&state=' + this.propData.state + '&zipcode=' + this.propData.zipcode + '&country=USA' + '&email=' + this.propData.email + '&type=' + this.propData.type + '&num_baths=' + this.propData.num_baths + '&num_beds=' + this.propData.num_beds + '&amenities=' + this.propData.amenities + '&lat=' + this.propData.latitude + '&longitude=' + this.propData.longitude
        var self = this

        // TODO: add the dynamic session info for the manager ID and the owner ID
          console.log(url)
          axios.get(url, {
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json'
            },
            mode: 'no-cors',
            credentials: 'include'
          }).then(function (response) {
            console.log('create/update property called: ' + JSON.stringify(response.data))
            if (response.data) {
              if (response.request.status === 200) {
                // self.notifyVue('ti-home', 'bottom', 'right', notifyTitle, 2)
              }
            } else {
              swal({
                type: 'info',
                title: 'Server error:' + response.error,
                text: '',
                confirmButtonClass: 'btn btn-success btn-fill',
                buttonsStyling: false
              })
              self.saveEnabled = true
            }
          }).catch(function (error) {
            console.log(error)
            self.saveEnabled = true
          })
      },
      notifyVue (icon, verticalAlign, horizontalAlign, message, color) {
        this.$notify(
          {
            component: {
              template: '<span>' + message + '</span>'
            },
            icon: icon,
            horizontalAlign: horizontalAlign,
            verticalAlign: verticalAlign,
            type: this.messageTypes[color]
          })
        self.loading = false
      },
      refresh() {
        this.loading = true
        var token = this.metaData.token
        var baseURL = this.metaData.baseURL
        var self = this
        var ID = this.propData.property_ID
        console.log(token, ID)

        const url = baseURL + '/properties/getPropertyImageByPropID?token=' + token + '&ID=' + ID
        axios.get(url, {
          dataType: 'json',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          mode: 'no-cors',
          credentials: 'include'
        })
        .then(function (response) {
          console.log('Get Properties images called in method ', response)
          console.log(response.data)

          var imagesVar = response.data.payload
          self.images = []
          self.rawImages = imagesVar
          console.log(self.images)
          for (var i = 0; i < imagesVar.length; i ++) {
            self.images.push(imagesVar[i].url);   
          }

          if (self.images.length == 0) {
            self.images.push('static/img/default_img.png')
          }
          self.saveProperty()
          self.loading = false
          self.$root.$emit('image_preview_Property', self.images[0])
        })
        .catch(function (error) {
          console.log(error)
          self.loading = false
        })
      },
      checkBtn (btn) {
        if (btn === 0) return true
        return false
      },
      handleMouseDown (e) {
        if (!this.checkBtn(e.button)) return
        this.lastX = e.clientX
        this.lastY = e.clientY
        this.isDraging = true
        e.stopPropagation()
      },
      handleMouseUp (e) {
        if (!this.checkBtn(e.button)) return
        this.isDraging = false
        this.lastX = this.lastY = 0
      },
      handleMouseMove (e) {
        if (!this.checkBtn(e.button)) return
        if (this.isDraging) {
          this.top = this.top - this.lastY + e.clientY
          this.left = this.left - this.lastX + e.clientX
          this.lastX = e.clientX
          this.lastY = e.clientY
        }
        e.stopPropagation()
      },
      zoomIn (e) {
        this.scale += 0.25
      },
      zoomOut () {
        if (this.scale !== 0) {
          this.scale -= 0.25
        }
      },
      rotate () {
        this.rotateDeg += 90
      },
      next () {
        if (this.imgIndex === this.imgList.length - 1) return
        this.reset()
        this.imgIndex += 1
        setTimeout(() => {
          this.imgTransitionStatus = !this.imgTransitionStatus
        }, 0)
      },
      prev () {
        if (this.imgIndex === 0) return
        this.reset()
        this.imgIndex -= 1
        setTimeout(() => {
          this.imgTransitionStatus = !this.imgTransitionStatus
        }, 0)
      },
      reset () {
        this.imgTransitionStatus = !this.imgTransitionStatus
        this.scale = 1
        this.rotateDeg = 0
      },
      closeDialog () {
        this.$emit('hide')
      },
      remove () {
        console.log('removed clicked i:', this.imgIndex);
        const oldIndex = this.imgIndex;
        if (!this.images || this.images.length == 0) {
          return;
        } else {

          if (this.imgIndex  == this.images.length - 1) { //At last picture
            if(this.images.length > 1) {
              this.imgIndex = this.imgIndex - 1;
            } else {
              this.imgIndex = 0;
            }

          }
          console.log('after removed clicked i:', this.imgIndex);
          // upload data to the server
          this.currentStatus = STATUS_SAVING
          var instance = this
          this.delete(oldIndex)
          .then(x => {
            this.currentStatus = STATUS_SUCCESS
            console.log('wtf')
            instance.refresh()
          })
          .catch(err => {
            this.uploadError = err.response
            this.currentStatus = STATUS_FAILED
          })    
          return
        }

        // this.imgIndex
      },
      delete (oldIndex) {
        this.loading = true
        const instance = this
        const token = this.metaData.token
        const BASE_URL = this.metaData.baseURL
        const url = `${BASE_URL}/files/delete?token=` + token + '&fileUrl='+ this.rawImages[oldIndex].url +'&fileId=' + this.rawImages[oldIndex].id
        return axios.get(url)
          .then(function (response) {
            console.log('Serious ', response)
            instance.refresh()
          })
      },
      init () {
        this.images = []
        this.propData = this.propertyData
        this.imgIndex = this.index
        this.imgTransitionStatus = true
        this.scale = 1
        this.rotateDeg = 0
        this.top = 0
        this.left = 0
        this.isDraging = false
        this.refresh()
      }
    },
    computed: {
      isInitial () {
        return this.currentStatus === STATUS_INITIAL
      },
      isSaving () {
        return this.currentStatus === STATUS_SAVING
      },
      isSuccess () {
        return this.currentStatus === STATUS_SUCCESS
      },
      isFailed () {
        return this.currentStatus === STATUS_FAILED
      },
      pagedData () {
        return this.tableData.slice(this.from, this.to)
      },
      imgList () {
        if (Array.isArray(this.images)) {
          return this.images
        } else {
          return [this.images]
        }
      },
      visibleImgSrc () {
        /*
        if (this.imgList == 0) {
          return 'static/img/default_img.png'
        } */
        return this.imgList[this.imgIndex]
      },
      imgTotal () {
        return this.imgList.length || 0
      },
      imgStyle: {
        get () {
          return {
            transform: `translate(-50%, -50%)
              scale(${this.scale})
              rotate(-${this.rotateDeg}deg)`,
            top: `calc(50% + ${this.top}px)`,
            left: `calc(50% + ${this.left}px)`
          }
        }
      }
    },
    watch: {
      visible (visible) {
        if (visible === true) {
          this.init()
        }
      }
    }
  }
</script>

<style scoped lang="scss">
  .icon {
    width: 1em; height: 1em;
    vertical-align: -0.15em;
    fill: currentColor;
    overflow: hidden;
  }
  .fade-enter-active,
  .fade-leave-active {
    transition: all 0.3s ease;
  }
  .fade-enter,
  .fade-leave-to {
    opacity: 0;
  }
  .img-swiper {
    position: relative;
    display: block;
  }
  .modal {
    z-index: 9998;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    margin: 0;
    background: rgba(0, 0, 0, 0.5);
  }
  .img-wrapper {
    margin: 0;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50% -50%);
    box-shadow: #555 0px 5px 20px 2px;
    cursor: move;
  }
  .img-wrapper.transition {
    transition: transform 0.3s ease-in-out;
  }
  .img {
    max-width: 80vw;
    max-height: 80vh;
    vertical-align: middle;
    position: relative;
  }

  .btn__prev,
  .btn__next,
  .btn__close {
    cursor: pointer;
    position: absolute;
    font-size: 60px;
    color: #fff;
    opacity: 0.6;
    transition: 0.15s linear;
  }
  .btn__prev:hover,
  .btn__next:hover,
  .btn__close:hover {
    opacity: 1;
  }
  .btn__prev.disable:hover,
  .btn__next.disable:hover,
  .btn__prev.disable,
  .btn__next.disable {
    cursor: default;
    opacity: 0.2;
  }
  .btn__next {
    top: 50%;
    right: 15%;
    font-size: 40px;
  }
  .btn__prev {
    top: 50%;
    left: 15%;
    font-size: 40px;
  }
  .btn__close {
    top: 10px;
    right: 10px;
    font-size: 40px;
  }
  .pagination-total {
    position: absolute;
    font-size: 16px;
    top: 16px;
    left: 16px;
    color: #000;
  }
  .toolbar-btns {
    user-select: none;
    position: absolute;
    bottom: 0;
    left: 50%;
    transform: translate(-50%);
    background: rgba(45, 45, 44, .8);
    border-radius: 4px;
    border-bottom-right-radius: 0;
    border-bottom-left-radius: 0;
    padding: 6px 24px 0;
  }
  .toobar-btn{
    cursor: pointer;
    display: inline-block;
    padding: 6px;
  }
  .toobar-btn .icon{
    width: 32px;
    height: 32px;
    fill: #fff;
    color: #fff;
  }
  .toobar-btn:hover .icon{
    fill: #54b4ee;
    color: #54b4ee;
    cursor: pointer;
  }
  .image-upload > input
  {
    display: none;
  }
  .vld-overlay {
  bottom: 0;
  left: 0;
  position: absolute;
  right: 0;
  top: 0;
  align-items: center;
  display: none;
  justify-content: center;
  overflow: hidden;
  z-index: 1
}

.vld-overlay.is-active {
  display: flex
}

.vld-overlay.is-full-page {
  z-index: 999;
  position: fixed
}

.vld-overlay .vld-background {
  bottom: 0;
  left: 0;
  position: absolute;
  right: 0;
  top: 0;
  background: #fff;
  opacity: 0.5
}

.vld-overlay .vld-icon {
  position: relative
}

.vld-parent {
  position: relative
}



</style>
